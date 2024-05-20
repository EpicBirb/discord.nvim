./fetch-icons.sh
echo "converting icons please wait ..."
[ ! -d "./icons/" ] && mkdir ./icons/
for FILE in ./vscode-icons/icons/*.svg; do
    # f=${FILE%.*}".webp;export-do";
    name=$(basename "$FILE" ".svg")
    if [[ $name == file_type_* ]] then
        inkscape/bin/inkscape.com "$FILE" -o "./icons/$name.png" -w 1024 -h 1024
        echo "exported $name";
        echo $?
    else
        echo "skipping $name";
    fi
done