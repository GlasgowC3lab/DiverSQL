WITH cs_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_order_number,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    WHERE cs.cs_ext_sales_price > 500                      -- predicate 1
      AND cs.cs_quantity > 1                               -- predicate 2
      AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2451500   -- predicate 3
    GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk, cs.cs_sold_time_sk, cs.cs_order_number
),
avg_price AS (
    SELECT AVG(cs.cs_ext_sales_price) AS avg_sales
    FROM catalog_sales cs
    WHERE cs.cs_ext_sales_price > 0
)
SELECT
    i.i_brand,
    r.r_reason_desc,
    seq.seq_num,
    SUM(ca.total_sales) AS sum_total_sales,
    COUNT(DISTINCT ca.cs_item_sk) AS distinct_items,
    (SELECT avg_sales FROM avg_price) AS avg_sales_ref
FROM cs_agg ca
JOIN catalog_returns cr
    ON cr.cr_item_sk = ca.cs_item_sk
   AND cr.cr_order_number = ca.cs_order_number
JOIN catalog_sales cs
    ON cs.cs_item_sk = ca.cs_item_sk
   AND cs.cs_order_number = ca.cs_order_number
   AND cs.cs_sold_time_sk = ca.cs_sold_time_sk
JOIN item i
    ON ca.cs_item_sk = i.i_item_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td
    ON ca.cs_sold_time_sk = td.t_time_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
   AND ss.ss_sold_time_sk = td.t_time_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_sold_time_sk = td.t_time_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_order_number = ws.ws_order_number
CROSS JOIN (SELECT DISTINCT i_brand FROM item LIMIT 5) b
CROSS JOIN (SELECT 1 AS seq_num UNION ALL SELECT 2 UNION ALL SELECT 3) seq
WHERE i.i_brand = b.i_brand                                 -- predicate 4
  AND ca.total_sales > (SELECT avg_sales FROM avg_price)   -- predicate 5 (scalar subquery comparison)
  AND ib.ib_lower_bound >= 30000                           -- predicate 6
GROUP BY GROUPING SETS (
    (i.i_brand, r.r_reason_desc, seq.seq_num),
    (i.i_brand, seq.seq_num),
    ()
)
HAVING SUM(ca.total_sales) > 10000
ORDER BY sum_total_sales DESC
LIMIT 100
