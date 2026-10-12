WITH store_return_agg AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns
    WHERE sr_return_quantity > 10      -- filter predicate on return quantity
    GROUP BY sr_customer_sk
),
web_sales_agg AS (
    SELECT
        ws_bill_customer_sk,
        ws_web_page_sk,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM web_sales
    WHERE ws_ext_sales_price > 500    -- filter predicate on sales price
    GROUP BY ws_bill_customer_sk, ws_web_page_sk
)
(
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        sra.total_return_amt,
        wsa.total_net_paid,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY wsa.total_net_paid DESC) AS gender_rank,
        ROW_NUMBER() OVER (ORDER BY wsa.total_net_paid DESC) AS overall_rank
    FROM customer c
    JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN store_return_agg sra
        ON sra.sr_customer_sk = c.c_customer_sk
    JOIN web_sales_agg wsa
        ON wsa.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON wsa.ws_web_page_sk = wp.wp_web_page_sk
    WHERE c.c_salutation = 'Mr.'
      AND cd.cd_credit_rating = 'Excellent'
      AND wp.wp_type = 'Content'
)
UNION
(
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        sra.total_return_amt,
        wsa.total_net_paid,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY wsa.total_net_paid DESC) AS gender_rank,
        ROW_NUMBER() OVER (ORDER BY wsa.total_net_paid DESC) AS overall_rank
    FROM customer c
    JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN store_return_agg sra
        ON sra.sr_customer_sk = c.c_customer_sk
    JOIN web_sales_agg wsa
        ON wsa.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON wsa.ws_web_page_sk = wp.wp_web_page_sk
    WHERE sra.total_return_amt > 2000        -- alternative filter focusing on high return amounts
)
ORDER BY overall_rank
LIMIT 100
