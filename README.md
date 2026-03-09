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