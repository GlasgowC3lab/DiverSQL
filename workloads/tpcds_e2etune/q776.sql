WITH sales_returns AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        cs.cs_sold_date_sk AS date_key,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales_amount,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN catalog_sales cs
        ON sr.sr_item_sk = cs.cs_item_sk
        AND sr.sr_customer_sk = cs.cs_bill_customer_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    GROUP BY s.s_store_sk, s.s_store_name, cs.cs_sold_date_sk
),
reason_agg AS (
    SELECT
        s.s_store_sk,
        cs.cs_sold_date_sk AS date_key,
        r.r_reason_desc,
        SUM(sr.sr_return_amt_inc_tax) AS total_reason_return_amount
    FROM store_returns sr
    JOIN catalog_sales cs
        ON sr.sr_item_sk = cs.cs_item_sk
        AND sr.sr_customer_sk = cs.cs_bill_customer_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY s.s_store_sk, cs.cs_sold_date_sk, r.r_reason_desc
),
ranked_reasons AS (
    SELECT
        s_store_sk,
        date_key,
        r_reason_desc,
        total_reason_return_amount,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk, date_key ORDER BY total_reason_return_amount DESC) AS rn
    FROM reason_agg
),
top_reasons AS (
    SELECT
        s_store_sk,
        date_key,
        array_agg(r_reason_desc) AS top_reasons
    FROM ranked_reasons
    WHERE rn <= 3
    GROUP BY s_store_sk, date_key
)
SELECT
    sr.s_store_name,
    sr.date_key,
    sr.total_sales_amount,
    sr.total_sales_profit,
    sr.total_return_amount,
    sr.total_return_loss,
    (sr.total_sales_amount - sr.total_return_amount) AS net_sales,
    (sr.total_sales_profit - sr.total_return_loss) AS net_profit,
    tr.top_reasons
FROM sales_returns sr
LEFT JOIN top_reasons tr
    ON sr.s_store_sk = tr.s_store_sk
    AND sr.date_key = tr.date_key
WHERE sr.date_key BETWEEN 2451545 AND 2451910
ORDER BY net_sales DESC
LIMIT 100
