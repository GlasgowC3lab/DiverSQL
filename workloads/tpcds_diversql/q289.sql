WITH sales_data AS (
    SELECT
        ws.ws_bill_customer_sk,
        ws.ws_net_paid_inc_ship,
        ws.ws_list_price,
        ws.ws_sold_time_sk,
        ws.ws_bill_cdemo_sk,
        c.c_email_address,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        td.t_am_pm
    FROM web_sales ws
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
),
subq1 AS (
    SELECT ws_bill_customer_sk
    FROM sales_data
    WHERE regexp_like(c_email_address, '^[A-Z][a-z]+\\.[A-Z][a-z]+@')
      AND t_am_pm = 'AM'
    GROUP BY ws_bill_customer_sk
    HAVING sum(ws_net_paid_inc_ship) > 2000
),
subq2 AS (
    SELECT ws_bill_customer_sk
    FROM sales_data
    WHERE c_first_name LIKE 'J%'
      AND regexp_extract(c_email_address, '\\.org$', 0) IS NOT NULL
    GROUP BY ws_bill_customer_sk
    HAVING count(*) >= 2
)
SELECT
    sd.ws_bill_customer_sk,
    concat(sd.c_first_name, ' ', sd.c_last_name) AS full_name,
    sd.c_email_address,
    sd.cd_gender,
    sd.t_am_pm,
    sum(sd.ws_net_paid_inc_ship) AS total_paid,
    avg(sd.ws_list_price) AS avg_list_price
FROM sales_data sd
WHERE sd.ws_bill_customer_sk IN (
    SELECT ws_bill_customer_sk FROM subq1
    INTERSECT
    SELECT ws_bill_customer_sk FROM subq2
)
GROUP BY
    sd.ws_bill_customer_sk,
    sd.c_first_name,
    sd.c_last_name,
    sd.c_email_address,
    sd.cd_gender,
    sd.t_am_pm
ORDER BY total_paid DESC
LIMIT 100
