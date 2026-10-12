WITH
    intersect_times AS (
        SELECT cr_returned_time_sk AS t_sk
        FROM catalog_returns
        WHERE cr_return_amount > 100
        INTERSECT
        SELECT ws_sold_time_sk AS t_sk
        FROM web_sales
        WHERE ws_net_paid > 500
    ),
    full_join AS (
        SELECT
            COALESCE(cr.cr_returned_time_sk, ws.ws_sold_time_sk) AS time_sk,
            cr.cr_return_amount,
            ws.ws_net_paid
        FROM catalog_returns cr
        FULL OUTER JOIN web_sales ws
            ON cr.cr_returned_time_sk = ws.ws_sold_time_sk
        WHERE (cr.cr_return_quantity > 1 OR ws.ws_quantity > 1)
    )
SELECT
    td.t_hour,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    COUNT(DISTINCT p.p_promo_id) AS distinct_promos,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(ss.ss_ext_sales_price) AS avg_sales,
    MIN(ss.ss_ext_sales_price) AS min_sales,
    MAX(ss.ss_ext_sales_price) AS max_sales,
    SUM(COALESCE(fj.cr_return_amount, 0)) AS total_return_amount,
    SUM(COALESCE(fj.ws_net_paid, 0)) AS total_web_net_paid,
    ROW_NUMBER() OVER (ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS rn
FROM store_sales ss
INNER JOIN time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
INNER JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
INNER JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
INNER JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
INNER JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
INNER JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
INNER JOIN web_sales ws
    ON ws.ws_sold_time_sk = td.t_time_sk
INNER JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
INNER JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
INNER JOIN full_join fj
    ON fj.time_sk = td.t_time_sk
WHERE td.t_hour BETWEEN 9 AND 17
  AND ca.ca_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND ss.ss_quantity > 2
  AND hd.hd_buy_potential = '1001-5000'
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_returned_time_sk = ss.ss_sold_time_sk
          AND cr2.cr_return_amount > 500
      )
  AND td.t_time_sk IN (SELECT t_sk FROM intersect_times)
GROUP BY td.t_hour, ca.ca_state
ORDER BY total_sales DESC
LIMIT 100
