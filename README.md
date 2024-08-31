# WordPress Deploy Archive GitHub Action

A custom GitHub Action to deploy a WordPress zip archive or directory (e.g. to a custom [WP Update Server](https://github.com/YahnisElsts/wp-update-server)) using [LFTP](https://lftp.yar.ru/)

### Usage Example

Place the following in `/.github/workflows/main.yml`

```yml
on: push
name: 🚀 Deploy WordPress Plugin on Push
jobs:
  build-deploy:
    name: 🎉 Deploy
    runs-on: ubuntu-latest
    steps:
      - name: 🚚 Checkout latest code
        uses: actions/checkout@v4

      - name: 🚀 Deploy Plugin Dir 
        uses: webshr/action-wp-deploy-archive@latest
        with:
          mode: dir # required; defaults to `zip`
          hostname: your-wp-update-server.com # required
          username: yourFtpUsername # required
          password: ${{ secrets.ftp_password }} # required
          protocol: sftp # required; defaults to ftp
          secure: true # optional; defaults to false
          debug: true # optional; defaults to false
          local-dir: / # optional; defaults to `/`
          remote-dir: /path/to/directory # optional; defaults to `/`
```

## Excluding files from the directory

You can specify files or directories to be excluded from an archive using a `.distignore` file. It's recommended to use a `.distignore` file, especially for built files in `.gitignore`. The `.gitattributes` file is useful for projects that don't run a build step and ensures consistency with files committed to WordPress.org.

`.gitignore` example:

```.gitignore
/.wordpress-org
/.git
/node_modules

.distignore
.gitignore
```

### Configuration

Add your keys directly to your .yml configuration file or referenced from the `Secrets` project store.

It is strongly recommended to save sensive credentials as secrets.


| **Key Name**    | **Required** | **Example**                         | **Default**                           | **Description**                                  |
| --------------- | ------------ | ----------------------------------- | ------------------------------------- | ------------------------------------------------ |
| `mode`          | yes          | `file`                              | `zip`                                 | Set mode (`zip`, `file` or `dir`)                |
| `hostname`      | yes          | `ftp.wpupdate.com`                  |                                       | Server hostname                                  |
| `username`      | yes          | `username@wpupdate.com`             |                                       | Server username                                  |
| `password`      | no           | `${{ secrets.pass }}`               |                                       | Server password                                  |
| `protocol`      | no           | `sftp`                              | `ftp`                                 | FTP Protocol (FTP or SFTP)                       |
| `secure`        | no           | `true`                              | `false`                               | Secure FTP connection                            |
| `verify`        | no           | `true`                              | `false`                               | Verify SSL certificate and hostname              |
| `file-name`     | no           | `index.php`                         |                                       | Name of the target file (with extension)         |
| `archive-name`  | no           | `my-plugin`                         | `${{ github.event.repository.name }}` | Name of the target archive (zip only)            |
| `local-dir`     | no           | `/dist-archive/`                    | `/`                                   | Path to the local directory (src)                |
| `remote-dir`    | no           | `/web/api/v1/packages`              | `/`                                   | Path to the remote directory (dest)              |
| `debug`         | no           | `true`                              | `false`                               | Enable debug mode                                |
| `chmod`         | no           | `u+rwx`                             | `false`                               | Set permissions for the uploaded directory       |
| `ignore`        | no           | `false`                             | `true`                                | Exclude files and directories from `.distignore` |
| `only-newer`    | no           | `true`                              | `false`                               | Upload only newer files                          |
| `clean-dir`     | no           | `true`                              | `false`                               | Clean the remote directory before uploading      |
| `auto-confirm`  | no           |                                     | `yes`                                 | Auto-confirm the upload                          |
| `pre-commands`  | no           | `mv /dest/project2 /temp/project2;` |                                       | Commands to run before deploying                 |
| `post-commands` | no           | `mv /temp/project2 /dest/project2;` |                                       | Commands to run after deploying                  |

### Credits

This action is inspired by and builds upon the work done from [Drone FTP(S) Plugin](https://github.com/cschlosser/drone-ftps)

### Further Reading

* [Custom WP Update Server](https://github.com/YahnisElsts/wp-update-server) by Yahnis Elsts
* [Offical LFTP manual](https://lftp.yar.ru/lftp-man.html)

### License

This action is licensed under the MIT License.