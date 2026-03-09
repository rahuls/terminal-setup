# terminal-setup

Bootstrap script and shell config to quickly set up a new machine.

## Test in Docker (Ubuntu)

Build image from this repo:

```bash
docker build -t terminal-setup-test .
```

Run a container with repo contents already copied to `/workspace`:

```bash
docker run --rm -it terminal-setup-test
```

Inside the container:

```bash
chmod +x setup.sh
./setup.sh
```

Notes:

- Containers do not automatically run SSH.
- `setup.sh` skips `chsh` when running in a container, since changing login shell is not needed there.

## Custom Zsh Files

Keep custom zsh files in repo at:

- `zsh/custom/aliases.zsh`
- `zsh/custom/functions.zsh`

`setup.sh` creates/updates these symlinks:

- `~/.oh-my-zsh/custom/aliases.zsh -> <repo>/zsh/custom/aliases.zsh`
- `~/.oh-my-zsh/custom/functions.zsh -> <repo>/zsh/custom/functions.zsh`

If a real file already exists at either destination, it is backed up with a timestamp before linking.