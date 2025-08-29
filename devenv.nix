{ pkgs, config, ... }:

{
  cachix.enable = false;

  packages = with pkgs; [
    pkgs.git
    pkgs.wp-cli
  ];

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
    sudo setcap 'cap_net_bind_service' ${pkgs.caddy}/bin/caddy
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
          name = "wordpress";
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
          root * .
          php_fastcgi unix/${config.languages.php.fpm.pools.web.socket}
          file_server
        '';
      };
    };
  };
}
