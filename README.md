# Oh my ZSH Docker Image


## Usage

While the image works, it is actually intended to be used to build other images,
specially custom-made devcontainers:

```Dockerfile
# Install Oh My ZSH:
COPY --from=vovimayhem/ohmyzsh:latest \
     --chown=my-username:my-username \
     /home/example-user/.oh-my-zsh /home/my-username/.oh-my-zsh

# Copy recommended zshrc file:
COPY --from=vovimayhem/ohmyzsh:latest \
     --chown=my-username:my-username \
     /home/example-user/.zshrc /home/my-username/.zshrc
```

Like that, you'll have Oh My ZSH installed!
