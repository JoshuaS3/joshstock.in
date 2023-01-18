# joshstock.in

Source code for compilation of the static joshstock.in. Include nginx conf and resty-gitweb subdomain conf files.

## Usage

```
sudo ./deploy [test|prod]
```

This is automated by the `post-receive` git hook to automatically deploy on a
git push to the production server. The deploy bash script automatically
installs required Python modules and runs the templating script
(`site/targets.py`). The templating script makes use of reusable generator
scripts to build pages from Markdown-defined content.
