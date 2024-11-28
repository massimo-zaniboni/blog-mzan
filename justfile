
default: build-image

# Build the image the first time.
build-image:
    docker build -t pelican .

run CMD:
    docker run --rm -it --network=host -p 8000:8000 --mount type=bind,source="$PWD",target=/local-dir pelican {{CMD}}

# Enter into the Docker container.
hugo-shell:
    just run bash

# serve demo site on port 8000, with also the drafts articles.
serve:
    just run "hugo server --buildDrafts --port 8000"

# publish to remote server, and update GitHub repo
publish:
    just run "hugo build --cleanDestinationDir --gc"
    rsync -Pav --delete -e "ssh -i /home/mzan/.ssh/guix-deploy" public/ root@mzan.dokmelody.org:/var/www/mzan.dokmelody.org/ --chown=nginx:nginx
    git push -u origin main
