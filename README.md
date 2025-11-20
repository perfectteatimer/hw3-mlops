# дз3 млопс


# Структура проекта

```
hw3-mlops/
│
├── docker-compose.yml
├── README.md
│
├── data/
│   └── train.csv
│
├── producer/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── send_to_kafka.py
│
├── clickhouse/
│   ├── init/
│   │   ├── 01_create_kafka_table.sql
│   │   ├── 02_create_target_table_step1.sql
│   │   └── 03_create_mv.sql
│   │
│   ├── query_max_category_per_state.sql
│   └── ddl_optimized_step2.sql
│
└── results/
    └── max_category_per_state.csv
```

---

# Краткое описание решения

Ниже перечислено, что делает каждая часть проекта:

* Kafka используется как очередь, через которую проходят строки из CSV.
* ClickHouse получает эти строки автоматически и записывает в таблицу.
* Python-скрипт `send_to_kafka.py` отправляет строки CSV по одной, без загрузки файла целиком в память.
* SQL-запрос использует функцию `argMax`, чтобы получить категорию самой крупной транзакции по каждому штату.
* В оптимизированной версии таблицы я применил разбиение по состояниям, сортировку по `(us_state, amount)` и тип `LowCardinality` для текстовых столбцов. 

---

# Порядок запуска проекта

## Шаг 0. Положить датасет.

```
data/train.csv ожидается что датасет будет лежать в папке data. Сейчас его там нет, так как он слишком тяжелый работы с git. Положите его туда перед дальнейшими шагами. 
```
---

## Шаг 1. Полностью очистить окружение

```
docker-compose down -v
```
---

## Шаг 2. Поднять Kafka и ClickHouse

```
docker-compose up -d redpanda clickhouse
```
---

## Шаг 3. Собрать образ продюсера

```
docker-compose build producer
```

---

## Шаг 4. Отправить строки CSV в Kafka

```
docker-compose run --rm producer python send_to_kafka.py
```

Ожидаем увидеть примерно такое сообщение:

```
sending rows: 786431it [...]
```

786431 — это количество строк в трейне, я посчитал просто заранее для дебага.

---

## Шаг 5. Проверить, что данные появились в ClickHouse

```
docker-compose exec clickhouse clickhouse-client -q "SELECT count() FROM transactions"
```

ClickHouse читает Kafka асинхронно, поэтому иногда команда может показать другое число (меньше). В этом случае достаточно повторить команду через пару секунд.

Ожидаемый результат:

```
786431
```

---

## Шаг 6. Выполнить основной SQL-запрос

Создать папку для результатов:

```
mkdir -p results
```

Выполнить запрос:

```
docker-compose exec -T clickhouse \
  clickhouse-client --multiquery < clickhouse/query_max_category_per_state.sql \
  > results/max_category_per_state.csv
```

Проверить количество строк:

```
wc -l results/max_category_per_state.csv
```

Ожидаемый результат:

```
51
```

Это количество штатов (включая возможные дополнительные строки).
---

## Шаг 7.Оптимизация структуры таблицы

Выполнить:

```
docker-compose exec -T clickhouse \
  clickhouse-client --multiquery < clickhouse/ddl_optimized_step2.sql
```

После выполнения можно проверить структуру таблицы:

```
docker-compose exec clickhouse clickhouse-client -q "DESCRIBE TABLE transactions"
```

Должно быть видно, что:

* у `us_state` и `cat_id` тип `LowCardinality(String)`
* таблица разбита по `PARTITION BY us_state`
* сортировка задана как `(us_state, amount)`

---

## Шаг 8. Снова загрузить CSV (после пересоздания таблицы)

Оптимизация пересоздаёт таблицу, поэтому нужно снова заполнить её данными:

```
docker-compose run --rm producer python send_to_kafka.py
```

Проверить:

```
docker-compose exec clickhouse clickhouse-client -q "SELECT count() FROM transactions"
```

Ожидаемый вывод:

```
786431
```

---

## Шаг 9. Проверить, что SQL-запрос работает после оптимизации

```
docker-compose exec -T clickhouse \
  clickhouse-client --multiquery < clickhouse/query_max_category_per_state.sql \
  > results/max_category_per_state.csv
```

Проверка:

```
wc -l results/max_category_per_state.csv
```

Ожидаемый вывод:

```
51
```

---

# Описание ключевых файлов проекта

### docker-compose.yml

Поднимает основные сервисы: Kafka (в моём случае Redpanda), ClickHouse и контейнер с продюсером.

### producer/send_to_kafka.py

Читает CSV построчно и отправляет каждую строку в Kafka.

### clickhouse/init/01_create_kafka_table.sql

Создаёт таблицу на движке Kafka, которая умеет читать сообщения из топика `transactions`.

### clickhouse/init/02_create_target_table_step1.sql

Первая версия таблицы MergeTree, в которую будут попадать данные.

### clickhouse/init/03_create_mv.sql

Переливает данные из Kafka-таблицы в основную таблицу.

### clickhouse/query_max_category_per_state.sql

Запрос, который находит категорию с максимальной суммой транзакции в каждом штате.

### clickhouse/ddl_optimized_step2.sql

Оптимизированная версия таблицы MergeTree.
Используется разбиение по штатам, сортировка по `(us_state, amount)` и типы LowCardinality.

### results/max_category_per_state.csv

Файл, который формируется в ходе работы кода.
---

# Заключение

В этот раз я постарался оформить md сильно подробнее (а то за дз1 снизили за это), так что по нему не должно быть проблемой разобраться в решении!
