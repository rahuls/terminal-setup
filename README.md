# terminal-setup

Bootstrap script and shell config to quickly set up a new machine.

## Make Commands

List available commands:

```bash
make help
```

Common usage:

```bash
make setup
make docker-build
make docker-run
```

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
chmod +x scripts/setup.sh
./scripts/setup.sh
```

Notes:

- Containers do not automatically run SSH.
- `scripts/setup.sh` skips `chsh` when running in a container, since changing login shell is not needed there.

## Custom Zsh Files

Keep custom zsh files in repo at:

- `zsh/custom/aliases.zsh`
- `zsh/custom/functions.zsh`

`scripts/setup.sh` creates/updates these symlinks:

- `~/.oh-my-zsh/custom/aliases.zsh -> <repo>/zsh/custom/aliases.zsh`
- `~/.oh-my-zsh/custom/functions.zsh -> <repo>/zsh/custom/functions.zsh`

If a real file already exists at either destination, it is backed up with a timestamp before linking.

## Zshrc Management

`scripts/setup.sh` calls `scripts/zshrc.sh` to ensure `~/.zshrc` contains:

- `ZSH_THEME="powerlevel10k/powerlevel10k"`
- your plugin list
- `source $ZSH/oh-my-zsh.sh`
- `source ~/.p10k.zsh` (if present)

Any existing non-managed lines in `~/.zshrc` are preserved below the managed block.

## Powerlevel10k

`scripts/setup.sh` delegates theme setup to `scripts/theme.sh`.

`scripts/theme.sh` installs Powerlevel10k into:

`~/.oh-my-zsh/custom/themes/powerlevel10k`

To reuse your existing prompt config without running `p10k configure`, place your config in repo at:

`zsh/.p10k.zsh`

Then `scripts/theme.sh` links:

`~/.p10k.zsh -> <repo>/zsh/.p10k.zsh`

If `zsh/.p10k.zsh` is not present, setup keeps any existing `~/.p10k.zsh` and does not run interactive init.