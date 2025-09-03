{ pkgs, config, ... }:

{
  cachix.enable = false;

  env.WP_VERSION = "6.8.2";
  env.WP_SHA1 = "03baad10b8f9a416a3e10b89010d811d9361e468";

  packages = with pkgs; [
    pkgs.git
    pkgs.wp-cli
    pkgs.nodejs_24
  ];

  enterShell = ''
    if [ ! -f wordpress-${config.env.WP_VERSION}.tar.gz ]; then
      echo "Fetching WordPress ${config.env.WP_VERSION}..."
      curl -o wordpress-${config.env.WP_VERSION}.tar.gz -SL https://wordpress.org/wordpress-${config.env.  WP_VERSION}.tar.gz \
        && echo "${config.env.WP_SHA1} *wordpress-${config.env.WP_VERSION}.tar.gz" | sha1sum -c - \
        && tar xzf wordpress-${config.env.WP_VERSION}.tar.gz -C ./wordpress \
        && echo "WordPress ${config.env.WP_VERSION} installed"
    fi
  '';

  languages.php = {
    enable = true;
    package = pkgs.php82.buildEnv {
      extensions = { all, enabled }: with all; enabled ++ [ redis pdo_mysql xdebug ];
      extraConfig = ''
        memory_limit = -1
        xdebug.mode = debug
        xdebug.start_with_request = yes
        xdebug.log_level = 0
        max_execution_time = 0
      '';
    };
    fpm.pools.web = {
      settings = {
        "clear_env" = "no";
        "pm" = "dynamic";
        "pm.max_children" = 10;
        "pm.start_servers" = 2;
        "pm.min_spare_servers" = 1;
        "pm.max_spare_servers" = 10;
      }; 
    };
  };

  certificates = [
    "wp.localhost"
  ];

  scripts.caddy-setcap.exec = ''
    sudo setcap 'cap_net_bind_service=+ep' ${pkgs.caddy}/bin/caddy
  '';

  services = {
    redis.enable = true;
    mysql = {
      enable = true;
      initialDatabases = [{ name = "wp"; }];
      settings.mysqld = {
        max_allowed_packet = "512M";
      };
      ensureUsers = [
        {
          name = "stephen";
          password = "wordpress";
          ensurePermissions = { "wp.*" = "ALL PRIVILEGES"; };
        } 
      ];
    };
    caddy = {
      enable = true;
      virtualHosts."wp.localhost" = {
        extraConfig = ''
          tls ${config.env.DEVENV_STATE}/mkcert/wp.localhost.pem ${config.env.DEVENV_STATE}/mkcert/wp.localhost-key.pem
          root * ./wordpress
          php_fastcgi unix/${config.languages.php.fpm.pools.web.socket}
          file_server
        '';
      };
    };
  };
}
