gh pr list                  # PRs abiertos del repo actual
gh pr view 1                # ver el PR 1 en la terminal
gh pr view 1 --web          # abrirlo en el browser
gh pr checks 1              # estado del CI
gh pr diff 1                # el diff completo
gh pr create                # crear PR (interactivo, desde la rama actual)
gh pr merge 1 --merge       # mergear conservando los commits

Sin número, casi todos asumen "el PR de la rama actual": gh pr view a secas te muestra el tuyo.

Para crear PRs sin el modo interactivo:

gh pr create --title "..." --body "..." --base main
gh pr create --fill          # usa los mensajes de commit como título y cuerpo
gh pr create --draft         # como borrador

Tres cosas que conviene saber ya:

1. --json + --jq es donde gh se vuelve potente. gh pr view 1 --json title,mergeable,commits te da datos estructurados en vez de texto para leer.

2. gh api es la vía de escape. Cuando un subcomando falla o no existe, hablás con la API REST directo: gh api repos/OWNER/REPO/pulls/1. 

Para explorar: gh <recurso> --help lista las acciones disponibles (gh pr --help).
