# Лабораторная работа №2

docker history 
```
IMAGE          CREATED          CREATED BY                                      SIZE      COMMENT
a9e77f9ed32c   39 minutes ago   ENTRYPOINT ["/opt/venv/bin/python" "app.py"]    0B        buildkit.dockerfile.v0
<missing>      39 minutes ago   HEALTHCHECK {Test:[CMD-SHELL python -c "impo…   0B        buildkit.dockerfile.v0
<missing>      39 minutes ago   USER apprunner                                  0B        buildkit.dockerfile.v0
<missing>      39 minutes ago   COPY --chown=apprunner:apprunner app/ . # bu…   20.5kB    buildkit.dockerfile.v0
<missing>      39 minutes ago   COPY /opt/venv /opt/venv # buildkit             35.2MB    buildkit.dockerfile.v0
<missing>      40 minutes ago   WORKDIR /home/apprunner/app                     16.4kB    buildkit.dockerfile.v0
<missing>      40 minutes ago   RUN |2 LAB_LOGIN=slava17recr LAB_TOKEN=cb997…   41kB      buildkit.dockerfile.v0
<missing>      40 minutes ago   ENV PATH=/opt/venv/bin:/usr/local/bin:/usr/l…   0B        buildkit.dockerfile.v0
<missing>      40 minutes ago   LABEL org.lab.login=slava17recr org.lab.toke…   0B        buildkit.dockerfile.v0
<missing>      40 minutes ago   ARG LAB_TOKEN=cb99727b990a3166999c02c3f3278e…   0B        buildkit.dockerfile.v0
<missing>      40 minutes ago   ARG LAB_LOGIN=slava17recr                       0B        buildkit.dockerfile.v0
<missing>      2 weeks ago      CMD ["python3"]                                 0B        buildkit.dockerfile.v0
<missing>      2 weeks ago      RUN /bin/sh -c set -eux;  for src in idle3 p…   16.4kB    buildkit.dockerfile.v0
<missing>      2 weeks ago      RUN /bin/sh -c set -eux;   apk add --no-cach…   57.9MB    buildkit.dockerfile.v0
<missing>      2 weeks ago      ENV PYTHON_SHA256=bfb74ad39efae27cda510f134a…   0B        buildkit.dockerfile.v0
<missing>      2 weeks ago      ENV PYTHON_VERSION=3.11.17                      0B        buildkit.dockerfile.v0
<missing>      2 weeks ago      ENV GPG_KEY=A035C8C19219BA821ECEA86B64E628F8…   0B        buildkit.dockerfile.v0
<missing>      2 weeks ago      RUN /bin/sh -c set -eux;  apk add --no-cache…   2.83MB    buildkit.dockerfile.v0
<missing>      2 weeks ago      ENV LANG=C.UTF-8                                0B        buildkit.dockerfile.v0
<missing>      2 weeks ago      ENV PATH=/usr/local/bin:/usr/local/sbin:/usr…   0B        buildkit.dockerfile.v0
<missing>      4 weeks ago      CMD ["/bin/sh"]                                 0B        buildkit.dockerfile.v0
<missing>      4 weeks ago      ADD alpine-minirootfs-3.24.2-x86_64.tar.gz /…   9.08MB    buildkit.dockerfile.v0
```

## Чем мой образ лучше


Данный проект содержит готовый к продакшн-окружению, максимально оптимизированный и безопасный Dockerfile для Python-приложений на базе Alpine Linux. Конфигурация разработана с учетом строгих требований к производительности, безопасности и ограничениям ресурсов (размер итогового образа менее 150 МБ, поддержка монтирования файловой системы в режиме только для чтения).

1. Многоэтапная сборка (Multi-stage build)

В финальный продакшн-образ на базе легковесного python:3.11-alpine переносится исключительно готовое виртуальное окружение /opt/venv.
Итоговый размер образа остаётся небольшим (< 150 МБ)

Пример кода:

```
COPY --from=builder /opt/venv /opt/venv 
```


2. Оптимизация кэширования слоев Docker

Файл зависимостей requirements.txt копируется и устанавливается отдельно до копирования исходного кода самого приложения.

Пример кода:

```
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY --chown=apprunner:apprunner app/ .
```

3. Строгая изоляция и отказ от root-привилегий (безопасность)

В финальном образе создается выделенный системный пользователь без суперправ

Пример кода:

```
RUN adduser -u 10042 -D -s /bin/sh apprunner
COPY --chown=apprunner:apprunner app/ .
USER apprunner
```

4. Совместимость с режимом --read-only (только чтение)

Переменные окружения PYTHONDONTWRITEBYTECODE=1 запрещают запись файлов байт-кода __pycache__ на диск, а PYTHONUNBUFFERED=1 отключает буферизацию потоков.

Пример кода:

```
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1
```

5. Встроенный HEALTHCHECK без утяжеления образа

Для проверки здоровья используется стандартная библиотека Python urllib.request, опрашивающая эндпоинт /health.

Пример кода:

```
HEALTHCHECK --interval=25s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; resp = urllib.request.urlopen('http://localhost:8000/health'); exit(0 if resp.status == 200 else 1)"
```

Ссылка на Docker Hub: https://hub.docker.com/r/slava17recr/image-lab/tags

# Правки:

# 1) Добавлены все недостоющие файлы в одну директорию 

# 2) Подтверждения работы контейнера с --read-only

Команда запуска в режиме только для чтения:

```
docker run -d --rm --read-only --tmpfs /tmp --tmpfs /run -p 8080:8000 slava17recr/image-lab:cb99727b

```

Вывод команды проверки логов/статуса:

```
curl http://localhost:8080/health
```
```
StatusCode        : 200
StatusDescription : OK
Content           : {"status":"ok","uptime":26.0}
                    
RawContent        : HTTP/1.1 200 OK
                    Connection: close
                    Content-Length: 30
                    Content-Type: application/json
                    Date: Mon, 19 Oct 2026 19:01:31 GMT
                    Server: Werkzeug/3.1.9 Python/3.11.17
                    
                    {"status":"ok","uptime":26.0}
                    
Forms             : {}
Headers           : {[Connection, close], [Content-Length, 30], [Content-Type, application/json], [Date, Mon, 19 Oct 2026 19:01:31 GMT]...}
Images            : {}
InputFields       : {}
Links             : {}
ParsedHtml        : mshtml.HTMLDocumentClass
RawContentLength  : 30

```

# 3) Запускаем контейнер в интерактивном режиме командой:

```
docker run --rm --read-only --tmpfs /tmp --tmpfs /run -p 8080:8000 slava17recr/image-lab:cb99727b
```
Логи контейнера:

127.0.0.1 - - [19/Oct/2026 19:10:21] "GET /health HTTP/1.1" 200 -

127.0.0.1 - - [19/Oct/2026 19:10:46] "GET /health HTTP/1.1" 200 -

127.0.0.1 - - [19/Oct/2026 19:11:11] "GET /health HTTP/1.1" 200 -

Во втором окне PowerShell останавливаем контейнер командой:

```
docker stop d22e66eac54ae63c8e75addad4f823652dff3acf4cfe9d49c5ed1bd99cf7b6b7
```
В первом окне где выходили логи выходит сообщение:

Shutting down...

Обработчик сигналов перехватил SIGTERM и завершил работу за доли секунды.

# 4) Итоговый размер образа 

Используем команду:

```
docker images
```

Вывод образа:
```
IMAGE                             ID             DISK USAGE   CONTENT SIZE   EXTRA
slava17recr/image-lab2:cb99727b   2164054edfa2        137MB         32.4MB 
```
# 5) Исправил опечатку в Readme файле настройки HEALTHCHECK 

Было: HEALTHCHECK --interval=25s --timeout=3s --start-period=5s --retries=5

Стало: HEALTHCHECK --interval=25s --timeout=3s --start-period=5s --retries=3

# 6) Файл .dockerignore сделан

Объяснение назначений пакетов:

build-base: Базовый пакет в Alpine Linux, содержащий стандартные инструменты компиляции, необходимые для сборки Python-пакетов, содержащих нативные расширения на C.

libffi-dev: Заголовочные файлы и библиотеки для Foreign Function Interface (FFI) библиотеки, которые требуются для компиляции Python-модулей 

musl-dev: Разработческий пакет стандартной библиотеки C, используемой в Alpine Linux по умолчанию. Необходим для корректной сборки и линковки бинарных зависимостей Python под Alpine.

# Динамическое изменение ROCKET_SIZE без пересборки

Проверяем переменную внутри запущенного контейнера

Запускаем контейнер в фоне с нужным размером:

```
docker run -d --name test-rocket -e ROCKET_SIZE=Small slava17recr/image-lab:cb99727b
```
Дальше проверяем переменную окружения внутри него командой:

```
docker exec test-rocket printenv ROCKET_SIZE
```

Выводит: Small

Останавливаем и удаляем наш контейнер командами:

```
docker stop test-rocket
docker rm test-rocket
```
И если теперь мы запустим ту же команду, но с -e ROCKET_SIZE=SuperBig, то команда printenv выводит SuperBig.
Это доказывает, что значение меняется без пересборки образа
