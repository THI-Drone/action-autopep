#!/bin/bash

# inputs:
# $1: true to apply changes regarding formatting
apply_changes=$1
# $2: true to use own pep8 file of repo
own_pep=$2
# $3: true commit the changes directly
commit=$3
# $4: commit msg
commit_msg=$4
# $5: commit user name
commit_user_name=$5
# $6: commit user email
commit_user_email=$6

check_pep() {
    # use pep8 file of repo if provided
    file=pep8
    # throw error if no pep8 file provided
    if ! [[ -f "$file" ]]; then
        echo "No pep8 file found."
        exit 1
    fi
}

check_diff_status() {
	config=$1
	level=$2
	if [ $2 -eq 0 ]; then
		# successfull execution, no differences
		echo "Autopep8 standards from $config config are met."
	elif [ $2 -eq 2 ]; then
		# successfull execution, with differences -> throw error
		echo "Autopep8 standards from $config config not met."
		exit 1
	else
		# execution failed -> throw error
		echo "An error with status $level occured"
		exit 1
	fi
}

check_app_status() {
	config=$1
	level=$2
	if [ $? -eq 0 ]; then
		# successfull application
		echo "Autopep from $config config applied."
	else
		# application failed -> throw error
		echo "An error with status $level occured"
		exit 1
	fi
}

# distinguish between --in-place mode diff
if [[ "$apply_changes" == "true" ]]; then
    if [[ "$own_pep" == "true" ]]; then
        check_pep
        autopep8 \
            --global-config=pep8 \
            --in-place \
            --recursive \
            .
		check_app_status "pep8" $?
    else
        autopep8 \
            --ignore E402 \
            --max-line-length 80 \
            --in-place \
            --recursive \
            .
        check_app_status "default" $?
    fi
else
    # decide if own pep8 file should be used
    if [[ "$own_pep" == "true" ]]; then
        check_pep
        # pep8 file exists --> use specific config
		output=$(autopep8 --global-config=pep8 --exit-code --diff --recursive .; exit ${PIPESTATUS[0]})
		check_diff_status "pep8" $?
    else
        # no pep8 file provided --> use default config with inline command
		output=$(autopep8 --ignore E402 --max-line-length 120 --exit-code --diff --recursive .; exit ${PIPESTATUS[0]})
        check_diff_status "default" $?
    fi
fi

if [[ "$commit" == "true" ]]; then
    # commit applied changes
    git config --local user.email "$commit_user_email"
    git config --local user.name "$commit_user_name"
    git add .
    if [ -z "$(git status --porcelain)" ]; then
        exit 0
    fi
    git commit -m "$commit_msg"
    git push origin HEAD:${GITHUB_REF}
fi
