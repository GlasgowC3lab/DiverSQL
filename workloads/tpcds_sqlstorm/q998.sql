WITH
sales AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        ss.ss_item_sk AS item_sk,
        SUM(ss.ss_net_profit) AS net_profit,
        COUNT(*) AS sales_cnt,
        'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY ss.ss_customer_sk, ss.ss_item_sk
    UNION ALL
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_item_sk AS item_sk,
        SUM(cs.cs_net_profit) AS net_profit,
        COUNT(*) AS sales_cnt,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY cs.cs_bill_customer_sk, cs.cs_item_sk
    UNION ALL
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_item_sk AS item_sk,
        SUM(ws.ws_net_profit) AS net_profit,
        COUNT(*) AS sales_cnt,
        'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY ws.ws_bill_customer_sk, ws.ws_item_sk
),
returns AS (
    SELECT
        sr.sr_customer_sk AS customer_sk,
        sr.sr_item_sk AS item_sk,
        SUM(sr.sr_net_loss) AS net_loss,
        'store' AS channel
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY sr.sr_customer_sk, sr.sr_item_sk
    UNION ALL
    SELECT
        cr.cr_refunded_customer_sk AS customer_sk,
        cr.cr_item_sk AS item_sk,
        SUM(cr.cr_net_loss) AS net_loss,
        'catalog' AS channel
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY cr.cr_refunded_customer_sk, cr.cr_item_sk
    UNION ALL
    SELECT
        wr.wr_refunded_customer_sk AS customer_sk,
        wr.wr_item_sk AS item_sk,
        SUM(wr.wr_net_loss) AS net_loss,
        'web' AS channel
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY wr.wr_refunded_customer_sk, wr.wr_item_sk
),
sales_returns AS (
    SELECT
        s.customer_sk,
        s.item_sk,
        COALESCE(s.net_profit, 0) - COALESCE(r.net_loss, 0) AS net_gain,
        s.sales_cnt,
        s.channel
    FROM sales s
    LEFT JOIN returns r
        ON s.customer_sk = r.customer_sk
        AND s.item_sk = r.item_sk
        AND s.channel = r.channel
),
ranked AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        concat_ws(' ', c.c_first_name, c.c_last_name) AS customer_name,
        i.i_item_id,
        i.i_product_name,
        sr.net_gain,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY sr.net_gain DESC) AS rn,
        CASE
            WHEN sr.net_gain IS NULL THEN 'No Sales'
            WHEN sr.net_gain > 0 THEN 'Profit'
            ELSE 'Loss'
        END AS profit_status,
        concat('Channel: ', sr.channel) AS channel_info,
        c.c_preferred_cust_flag,
        c.c_birth_year,
        c.c_birth_month,
        c.c_birth_day,
        c.c_birth_country
    FROM sales_returns sr
    JOIN customer c ON sr.customer_sk = c.c_customer_sk
    JOIN item i ON sr.item_sk = i.i_item_sk
    WHERE sr.net_gain IS NOT NULL
      AND COALESCE(c.c_preferred_cust_flag, 'N') = 'Y'
      AND (c.c_birth_year BETWEEN 1950 AND 2000 OR c.c_birth_year IS NULL)
      AND (c.c_birth_country IS NULL OR c.c_birth_country = 'United States')
),
blacklist AS (
    SELECT DISTINCT sr.sr_customer_sk AS c_customer_sk
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE sr.sr_net_loss > 1000
)
SELECT
    r.customer_name,
    r.c_customer_id,
    r.i_item_id,
    r.i_product_name,
    r.net_gain,
    r.profit_status,
    r.channel_info,
    (SELECT MAX(d.d_year)
     FROM store_sales ss
     JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
     WHERE ss.ss_customer_sk = r.c_customer_sk) AS last_purchase_year,
    CASE
        WHEN r.c_birth_year IS NULL THEN NULL
        ELSE FLOOR((2022 - r.c_birth_year) / 10) * 10
    END AS birth_decade,
    (r.c_birth_month * 100 + COALESCE(r.c_birth_day, 0)) AS birth_month_day_code
FROM (
    SELECT * FROM ranked WHERE rn <= 5 AND profit_status = 'Profit'
    UNION ALL
    SELECT * FROM ranked WHERE rn <= 5 AND profit_status = 'Loss'
) r
WHERE NOT EXISTS (SELECT 1 FROM blacklist b WHERE b.c_customer_sk = r.c_customer_sk)
ORDER BY r.customer_name, r.net_gain DESC
