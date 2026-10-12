WITH base AS (
    SELECT
        i.i_item_id,
        sm.sm_carrier,
        ib.ib_income_band_sk,
        SUM(cs.cs_ext_sales_price)               AS total_sales,
        SUM(cr.cr_return_amount)                 AS total_returns,
        COUNT(DISTINCT cs.cs_order_number)       AS orders
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
        AND cr.cr_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE i.i_brand = 'Brand#12'
      AND sm.sm_carrier = 'ALLIANCE'
      AND ib.ib_upper_bound > 50000
      AND cs.cs_ext_sales_price > 1000
    GROUP BY i.i_item_id, sm.sm_carrier, ib.ib_income_band_sk
),
union_set AS (
    SELECT i_item_id, sm_carrier AS carrier, total_sales, total_returns
    FROM base
    WHERE total_sales > 5000
    UNION
    SELECT i_item_id, sm_carrier AS carrier, total_sales, total_returns
    FROM base
    WHERE total_returns > 1000
),
except_set AS (
    SELECT i_item_id FROM base WHERE total_sales > 8000
    EXCEPT
    SELECT i_item_id FROM base WHERE total_returns > 3000
)
SELECT
    carrier,
    AVG(total_sales) AS avg_sales,
    CASE WHEN AVG(total_sales) > 10000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
FROM union_set
WHERE i_item_id NOT IN (SELECT i_item_id FROM except_set)
GROUP BY carrier
HAVING AVG(total_sales) > 2000
ORDER BY avg_sales DESC
