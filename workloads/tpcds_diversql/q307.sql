WITH diff_items AS (
    SELECT sr_item_sk FROM store_returns
    EXCEPT
    SELECT cs_item_sk FROM catalog_sales
)
SELECT
    i.i_item_id,
    i.i_brand,
    i.i_category,
    s.s_store_sk,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_quantity) AS avg_quantity,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    MIN(cs.cs_sales_price) AS min_sales_price,
    MAX(cs.cs_sales_price) AS max_sales_price,
    (
        SELECT SUM(sr2.sr_return_amt)
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = s.s_store_sk
    ) AS total_store_return_amt
FROM diff_items di
JOIN item i
    ON i.i_item_sk = di.sr_item_sk
JOIN catalog_sales cs TABLESAMPLE BERNOULLI (10)
    ON cs.cs_item_sk = i.i_item_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN web_returns wr
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND s.s_state = 'CA'
    AND i.i_brand = 'Brand#12'
    AND c.c_birth_year = 1975
    AND cc.cc_state = 'TX'
    AND wp.wp_link_count > 10
GROUP BY
    i.i_item_id,
    i.i_brand,
    i.i_category,
    s.s_store_sk
LIMIT 100
