#!/bin/bash

filename=database.txt                   # パスワード保存先のファイル名を決める
COMMON_KEY=$(printenv QUEST_PASSPHRASE) # 暗号化・復号化するためのパスフレーズを環境変数から読み込む

# 同名のサービスがないかをチェックする関数
function is_sameservice() {
    grep -q "^${1}:" "${filename}" 2>/dev/null
}

# 文字列にコロンが含まれているかをチェックする関数
function is_colon() {
    echo "${1}" | grep -q ":" 2>/dev/null
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
        gpg \
            --passphrase="${COMMON_KEY}" \
            --batch \
            --yes \
            --output "${filename}" \
            --yes \
            --decrypt \
            "${filename}.gpg" 2>/dev/null

        # 入力のバリデーション
        is_sameservice "${servicename}"
        if [[ $? == 0 ]]; then
            echo "既に同名のサービス名が登録されています。サービス名入力からやり直して下さい。"
            continue
        fi
        is_colon "${servicename}${username}${password}"
        if [[ $? == "0" ]]; then
            echo "登録にコロンは使用できません。サービス名入力からやり直して下さい。"
            continue
        fi
        # 追記＆暗号化
        echo "${servicename}:${username}:${password}" >>"${filename}" &&
            echo "${COMMON_KEY}" | gpg --passphrase-fd 0 --batch --yes --symmetric --cipher-algo AES256 "${filename}" &&
            rm "${filename}" &&
            echo "パスワードの追加は成功しました。"
        read -p "次の選択肢から入力してください(Add Password/Get Password/Exit)：" selection
    elif [[ ${selection} == "Get Password" ]]; then
        read -p "サービス名を入力してください：" servicename

        # ファイルの復号化
        gpg \
            --passphrase="${COMMON_KEY}" \
            --batch \
            --yes \
            --output "${filename}" \
            --yes \
            --decrypt \
            "${filename}.gpg" 2>/dev/null
        if [[ $? == "0" ]]; then
            info=$(grep "^${servicename}:" "${filename}")
        fi
        if [[ ${info} ]]; then
            servicename=${info%%:*}
            tmp=${info#*:}
            username=${tmp%%:*}
            password=${info##*:}
            echo
            echo "サービス名：${servicename}"
            echo "ユーザー名：${username}"
            echo "パスワード：${password}"
            # 暗号化
            echo "${COMMON_KEY}" | gpg --passphrase-fd 0 --batch --yes --symmetric --cipher-algo AES256 "${filename}" &&
                rm "${filename}"
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
done
