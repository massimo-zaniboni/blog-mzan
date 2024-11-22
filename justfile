
make:
    make html

clean:
    make clean

# serve demo site on port 8000
serve:
    make devserver

publish:
    make publish
    rsync -Pav --delete -e "ssh -i /home/mzan/.ssh/guix-deploy" output/ root@mzan.dokmelody.org:/var/www/mzan.dokmelody.org/ --chown=nginx:nginx
