# PHP-FPM 8.4 – Alpine (Optimisé pour Laravel)

Cette image fournit un environnement PHP-FPM 8.4 léger, rapide et optimisé pour exécuter des applications Laravel en production.
Elle est basée sur Alpine Linux, inclut Composer, Doppler, et un ensemble minimal mais complet de libs et extensions PHP nécessaires à Laravel.

## Installation

Pour récupérer l’image depuis le registry Scaleway :
```bash
docker pull rg.fr-par.scw.cloud/registry-par-ixys/containers/web/php-fpm-8.4:latest
```

Pour la version SLIM :
```bash
docker pull rg.fr-par.scw.cloud/registry-par-ixys/containers/web/php-fpm-8.4:slim
```

---
## Fonctionnalités principales
- Base : php:8.4-fpm-alpine
- Image SLIM fortement allégée (aucune dépendance inutile en runtime)
- Configuration PHP & FPM pré-intégrée via /config
- Extensions PHP compatibles Laravel
- Support GD complet (JPEG / WEBP / PNG / Freetype)
- Redis via PECL
- Doppler CLI pré-installé
- Optimisée pour K8S (healthchecks, non-root user, entrées custom)

---

## Extensions PHP incluses

| Extension | Description |
|----------|-------------|
| bcmath | Calculs haute précision |
| ctype | Requis par Laravel |
| exif | Métadonnées images |
| gd | Images (jpeg/webp/png/freetype) |
| intl | Localisation, formatage |
| mbstring | Manipulation UTF-8 |
| pcntl | Tâches / Horizon |
| pdo | Base PDO |
| pdo_mysql | MySQL / MariaDB |
| opcache | Accélération PHP |
| zip | Compression, storage Laravel |
| redis (PECL) | Cache/store Redis |

---

## Librairies Système incluses (runtime uniquement)

| Lib | Usage |
|-----|-------|
| ca-certificates | HTTPS |
| curl | Healthchecks, monitoring |
| bash | Scripts Laravel |
| git | Deploy, composer private |
| icu-libs | Required intl |
| libpng / jpeg / webp / freetype | GD |
| libzip | zip PHP |
| oniguruma | mbstring |
| libxml2 | XML |
| zlib | zip/pdo |

Aucune lib inutile en production (pas de node, npm, make, gcc, imagemagick, mysql-client, etc.).

---

## Doppler

L’image embarque Doppler CLI pour gérer les secrets K8s ou runtime.

```bash
doppler secrets download
```

---

## Utilisation locale

```bash
docker run --rm -it   -v "$PWD":/app   -p 9000:9000   rg.fr-par.scw.cloud/registry-par-ixys/containers/web/php-fpm-8.4:latest
```

---

## Variables et configuration

Les fichiers de configuration PHP/FPM sont injectés depuis :

```
/config/base-*.ini
/config/prod-*.ini
/config/fpm/*.conf
```

---

## Healthcheck

L’image inclut un script :

```
healthcheck-liveness
```

---

## Entrypoint

Entrypoint par défaut :

```
entrypoint-prod
```

Commande par défaut : `php-fpm`.

---

## Contribution

Toute PR sur l'image Docker doit respecter :

- Un Dockerfile **minimal**, sans dépendences inutiles
- Pas d’outils de build dans l’image finale
- Aucune modification sans justification de sécurité/performance
