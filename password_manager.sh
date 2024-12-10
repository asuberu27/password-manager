#!/bin/bash
filename=database.txt # パスワード保存先のファイル名を決める
echo "パスワードマネージャーへようこそ！"
read -p "次の選択肢から入力してください(Add Password/Get Password/Exit)：" selection
echo
while [ true ]; do
    if [[ ${selection} == "Add Password" ]]; then
        read -p "サービス名を入力してください：" servicename
        read -p "ユーザー名を入力してください：" username
        read -p "パスワードを入力してください：" password
        echo "${servicename}:${username}:${password}" >>"${filename}" && echo -e "\nパスワードの追加は成功しました。"
        read -p "次の選択肢から入力してください(Add Password/Get Password/Exit)：" selection
    elif [[ ${selection} == "Get Password" ]]; then
        read -p "サービス名を入力してください：" servicename
        info=$(grep "${servicename}:" database.txt)
        if [[ ${info} ]]; then
            servicename=${info%%:*}
            tmp=${info#*:}
            username=${tmp%%:*}
            password=${info##*:}
            echo
            echo "サービス名：${servicename}"
            echo "ユーザー名：${username}"
            echo "パスワード：${password}"
        else
            echo "そのサービスは登録されていません。"
        fi
        echo
        read -p "次の選択肢から入力してください(Add Password/Get Password/Exit)：" selection
    elif [[ ${selection} == "Exit" ]]; then
        echo "Thank you!"
        break
    else
        read -p "入力が間違えています。Add Password/Get Password/Exit から入力してください。" selection
    fi
    echo
done
