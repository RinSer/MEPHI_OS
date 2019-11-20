#!/bin/bash

THIS_NAME=$0
FILE_PATH=$1
LINE_COUNT=$2
NUM_ARGS=$#

# Отобразить пример вызова
usage() {
        echo "Пример вызова: $THIS_NAME путь_к_файлу количество_строк" 1>&2
}

# Функция для освобождения реcурсов после исполнения
clean_up() {
        stty echo && exit $1
}

# Отобразить сообщение об ошибке и закончить
error_exit() {
        echo "$FILE_PATH: ${1:-\"Неизвестная ошибка\"}" 1>&2
        clean_up 1
}

# Валидация исходных параметров
check_arguments() {
        if [ $NUM_ARGS != "2" ]; then
                usage
                error_exit "Необходимо указать путь к файлу и количество строк!"
        fi
        if ! [[ $LINE_COUNT =~ ^[0-9]+$ ]]; then
                usage
                error_exit "Второй параметр должен быть целым числом!"
        fi
}

# Валидация существования файла и наличия прав на запись
check_file_exists_and_writable() {
        if ! [ -r $1 ]; then
                error_exit "Не возможно прочитать файл $1!"
        fi
        if ! [ -w $1 ]; then
                error_exit "Не возможно изменять файл $1!"
        fi
}

# Ожидание команды завершения
wait_finish() {
        echo "Нажмите <ctrl+Y>, чтобы завершить работу"
        stty_init=$(stty -g)
        stty susp ^y
        trap "stty ${stty_init} && clean_up 0" SIGTSTP
}

# Ожидание интерактивного ввода пути к второму файлу
wait_second_file() {
        stty echo
        read -p "Введите путь до второго файла: " FILE_PATH
        check_file_exists_and_writable $FILE_PATH
        echo "Нажмите <ctrl+C>, чтобы удалить первую и последнюю строки файла $FILE_PATH"
        stty -echo
        trap cut_second_file SIGINT
}

# Удаление строк из файла, переданного как параметр
cut_first_file() {
        trap - SIGQUIT
        sed -i -e "1,${LINE_COUNT}d" $FILE_PATH
        wait_second_file
}

# Удаление первой и последней строки второго файла
cut_second_file() {
        trap - SIGINT
        sed -i -e "1,1d; $,1d" $FILE_PATH
        wait_finish
}

# Логика начала процедуры
start_procedure() {
        check_arguments
        check_file_exists_and_writable $FILE_PATH

        echo "Нежмите <ctrl+\> чтобы удалить $LINE_COUNT строк из файла $FILE_PATH"
        stty -echo
        trap cut_first_file SIGQUIT
        while true; do true; done
}

# Запускаем процедуру
start_procedure