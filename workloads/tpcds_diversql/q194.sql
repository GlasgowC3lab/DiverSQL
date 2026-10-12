WITH sales_agg AS (
    SELECT i.i_item_sk,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           AVG(ws.ws_ext_sales_price) AS avg_sales,
           COUNT(*) AS sales_cnt,
           MAX(ws.ws_web_site_sk) AS web_site_sk
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE w.web_company_name = 'cally'
      AND ws.ws_ext_wholesale_cost > 1000
      AND ws.ws_quantity >= 2
      AND ws.ws_promo_sk IN (1137, 876)
      AND ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY i.i_item_sk
),
returns_agg AS (
    SELECT sr.sr_item_sk,
           SUM(sr.sr_return_amt) AS total_returns,
           COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%defect%'
      AND sr.sr_return_quantity > 0
      AND sr.sr_return_amt > 0
    GROUP BY sr.sr_item_sk
),
promo_agg AS (
    SELECT p.p_item_sk,
           COUNT(DISTINCT p.p_promo_sk) AS promo_cnt,
           SUM(p.p_cost) AS promo_cost
    FROM promotion p
    JOIN item i ON p.p_item_sk = i.i_item_sk
    WHERE p.p_purpose = 'Unknown'
      AND p.p_response_target = 1
    GROUP BY p.p_item_sk
),
intersect_items AS (
    SELECT i_item_sk FROM sales_agg
    INTERSECT
    SELECT p_item_sk FROM promo_agg
)
SELECT i.i_item_id,
       i.i_product_name,
       sa.total_sales,
       sa.avg_sales,
       ra.total_returns,
       pa.promo_cnt,
       pa.promo_cost,
       w.web_name
FROM intersect_items ii
JOIN item i ON ii.i_item_sk = i.i_item_sk
LEFT JOIN sales_agg sa ON i.i_item_sk = sa.i_item_sk
LEFT JOIN returns_agg ra ON i.i_item_sk = ra.sr_item_sk
LEFT JOIN promo_agg pa ON i.i_item_sk = pa.p_item_sk
JOIN web_site w ON sa.web_site_sk = w.web_site_sk
WHERE i.i_brand = 'Brand#12'
  AND i.i_category = 'Sports'
ORDER BY sa.total_sales DESC
LIMIT 100
