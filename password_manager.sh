#!/bin/bash

filename=database.txt                   # パスワード保存先のファイル名を決める
COMMON_KEY=$(printenv QUEST_PASSPHRASE) # 暗号化・復号化するためのパスフレーズを環境変数から読み込む

function decrypt_file {
    gpg \
        --passphrase="${COMMON_KEY}" \
        --batch \
        --yes \
        --output "${filename}" \
        --yes \
        --decrypt \
        "${filename}.gpg" 2>/dev/null
}

function encrypt_file {
    echo "${COMMON_KEY}" | gpg --passphrase-fd 0 --batch --yes --symmetric --cipher-algo AES256 "${filename}" 2>/dev/null
    rm "${filename}" 2>/dev/null
}

echo "パスワードマネージャーへようこそ！"
read -p "次の選択肢から入力してください(Add Password/Get Password/Exit)：" selection
while [ true ]; do
    echo
    if [[ ${selection} == "Add Password" ]]; then
        read -p "サービス名を入力してください：" servicename
        read -p "ユーザー名を入力してください：" username
        read -p "パスワードを入力してください：" password
        echo

        # ファイルの復号化
        decrypt_file

        # 入力のバリデーション
        grep -q "^${servicename}:" "${filename}" 2>/dev/null
        if [[ $? == 0 ]]; then
            echo "既に同名のサービス名が登録されています。サービス名入力からやり直して下さい。"
            continue
        fi
        echo "${servicename}${username}${password}" | grep -q ":" 2>/dev/null
        if [[ $? == "0" ]]; then
            echo "登録文字に半角のコロンは使用できません。サービス名入力からやり直して下さい。"
            encrypt_file
            continue
        fi
        echo "${servicename}${username}${password}" | grep -q "" 2>/dev/null
        if [[ "${servicename}" == "" || "${username}" == "" || "${password}" == "" ]]; then
            echo "1文字以上入力してください。サービス名入力からやり直して下さい。"
            encrypt_file
            continue
        fi

        # ファイルに追記＆暗号化
        echo "${servicename}:${username}:${password}" >>"${filename}"
        encrypt_file
        echo "パスワードの追加は成功しました。"

        read -p "次の選択肢から入力してください(Add Password/Get Password/Exit)：" selection
    elif [[ ${selection} == "Get Password" ]]; then
        read -p "サービス名を入力してください：" servicename

        # ファイルの復号化
        decrypt_file

        #復号化に成功した場合、サービス名が保存されているかを確認
        if [[ $? == "0" ]]; then
            is_registered=$(grep "^${servicename}:" "${filename}")
        fi
        if [[ ${is_registered} ]]; then
            servicename=${is_registered%%:*}
            tmp=${is_registered#*:}
            username=${tmp%%:*}
            password=${is_registered##*:}
            echo
            echo "サービス名：${servicename}"
            echo "ユーザー名：${username}"
            echo "パスワード：${password}"
        else
            echo "そのサービスは登録されていません。"
        fi

        # ファイルの暗号化
        encrypt_file

        echo
        read -p "次の選択肢から入力してください(Add Password/Get Password/Exit)：" selection
    elif [[ ${selection} == "Exit" ]]; then
        echo "Thank you!"
        break
    else
        read -p "入力が間違えています。Add Password/Get Password/Exit から入力してください。" selection
    fi
done
