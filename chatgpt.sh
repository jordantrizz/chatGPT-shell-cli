#!/bin/bash
echo -e "Welcome to chatgpt. You can quit with '\033[36mexit\033[0m'."
running=true

# create history file
if [ ! -f ~/.chatgpt_history ]; then
	touch ~/.chatgpt_history
fi

while $running; do
	echo -e "\nEnter a prompt:"
	read prompt

	if [ "$prompt" == "exit" ]; then
		running=false
	elif [[ "$prompt" =~ ^image: ]]; then
		image_url=$(curl https://api.openai.com/v1/images/generations \
			-sS \
			-H 'Content-Type: application/json' \
			-H "Authorization: Bearer $OPENAI_TOKEN" \
			-d '{
    		"prompt": "'"${prompt#*image:}"'",
    		"n": 1,
    		"size": "512x512"
	}' | jq -r '.data[0].url')
		echo -e "\n\033[36mchatgpt \033[0mYour image was created. \n\nLink: ${image_url}\n"
		if [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
			curl -sS $image_url -o temp_image.png
			imgcat temp_image.png
			rm temp_image.png
		else
			echo "Would you like to open it? (Yes/No)"
			read answer
			if [ "$answer" == "Yes" ] || [ "$answer" == "yes" ] || [ "$answer" == "y" ] || [ "$answer" == "Y" ] || [ "$answer" == "ok" ]; then
				open "${image_url}"
			fi
		fi
	elif [[ "$prompt" == "history" ]]; then
		echo -e	"\n$(cat ~/.chatgpt_history)"
	else
		# escape quotation marks
		escaped_prompt=$(echo "$prompt" | sed 's/"/\\"/g')
		# request to OpenAI API
		response_curl=$(curl https://api.openai.com/v1/completions \
			-sS \
			-H 'Content-Type: application/json' \
			-H "Authorization: Bearer $OPENAI_TOKEN" \
			-d '{
  			"model": "text-davinci-003",
  			"prompt": "'"${escaped_prompt}"'",
  			"max_tokens": 1000,
  			"temperature": 0.7
			}')

		if echo "$response_curl" | jq -e '.error' >/dev/null; then
			echo "Something went wrong"
			echo $response_curl
			exit 1
		else
			echo "Response:"
			response=$(echo $response_curl | jq -r '.choices[].text' | sed '1,2d')
			echo -e "\n\033[36mchatgpt \033[0m\n${response}"
		fi

		timestamp=$(date +"%d/%m/%Y %H:%M")
		echo -e "$timestamp $prompt \n$response \n" >> ~/.chatgpt_history
	fi
done