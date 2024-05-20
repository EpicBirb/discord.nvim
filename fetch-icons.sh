echo "fetching from https://github.com/vscode-icons/vscode-icons"
# https://medium.com/@gabrielcruz_68416/clone-a-specific-folder-from-a-github-repository-f8949e7a02b4
[ ! -d "vscode-icons" ] && git clone --no-checkout --depth 1 --sparse --filter=blob:none https://github.com/vscode-icons/vscode-icons.git
cd vscode-icons
git sparse-checkout set --cone
git checkout master
git sparse-checkout set icons/
echo "finished"