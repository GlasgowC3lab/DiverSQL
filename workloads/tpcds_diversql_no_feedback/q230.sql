WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cp.cp_department,
        cp.cp_type,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        c.c_preferred_cust_flag,
        inv.inv_quantity_on_hand,
        sr.sr_net_loss,
        wr.wr_fee,
        ws.web_state,
        ws.web_name,
        word
    FROM date_dim d
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
        AND cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN (
        SELECT * FROM web_returns TABLESAMPLE BERNOULLI (10)
    ) wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    CROSS JOIN UNNEST(split(cp.cp_description, ' ')) AS t(word)
    WHERE d.d_year = 2001
      AND cp.cp_type = 'monthly'
      AND cs.cs_ext_discount_amt > 500
      AND c.c_preferred_cust_flag = 'Y'
      AND inv.inv_quantity_on_hand > 0
      AND sr.sr_net_loss > 100
      AND wr.wr_fee < 50
      AND ws.web_state = 'CA'
),
agg AS (
    SELECT
        d_year,
        cp_department,
        web_state,
        SUM(cs_net_profit) AS total_profit,
        SUM(cs_ext_discount_amt) AS total_discount,
        COUNT(*) AS txn_cnt
    FROM base
    GROUP BY CUBE (d_year, cp_department, web_state)
)
SELECT
    d_year,
    cp_department,
    web_state,
    total_profit,
    total_discount,
    txn_cnt,
    total_profit / NULLIF(txn_cnt, 0) AS avg_profit_per_txn
FROM agg
WHERE total_discount > 1000
ORDER BY total_profit DESC
