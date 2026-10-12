WITH sales_agg AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        w.w_warehouse_name,
        cs.cs_sold_date_sk,
        SUM(cs.cs_net_paid) AS daily_net_paid,
        SUM(cs.cs_quantity) AS daily_qty
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE w.w_warehouse_name LIKE '%WH%'
      AND regexp_like(cc.cc_name, '^A')
      AND regexp_like(c.c_email_address, '@example\\.com$')
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        w.w_warehouse_name,
        cs.cs_sold_date_sk
)
SELECT
    cc_call_center_id,
    cc_name,
    w_warehouse_name,
    cs_sold_date_sk,
    daily_net_paid,
    daily_qty,
    regexp_extract(cc_name, '^([A-Za-z]+)') AS name_first_word,
    substring(cc_name, 1, 3) AS name_prefix3,
    SUM(daily_net_paid) OVER (
        PARTITION BY cc_call_center_id
        ORDER BY cs_sold_date_sk
        ROWS UNBOUNDED PRECEDING
    ) AS running_net_paid
FROM sales_agg
ORDER BY running_net_paid DESC
LIMIT 100
