WITH sales_base AS (
   SELECT
      ws.ws_web_site_sk,
      ws.ws_ship_mode_sk,
      ws.ws_web_page_sk,
      ws.ws_promo_sk,
      ws.ws_order_number,
      ws.ws_net_paid,
      wr.wr_return_amt,
      ca.ca_state,
      p.p_channel_dmail,
      wsite.web_market_manager
   FROM web_sales ws
   JOIN customer_address ca
     ON ws.ws_bill_addr_sk = ca.ca_address_sk
   JOIN ship_mode sm
     ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN promotion p
     ON ws.ws_promo_sk = p.p_promo_sk
   JOIN web_page wp
     ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_site wsite
     ON ws.ws_web_site_sk = wsite.web_site_sk
   LEFT JOIN web_returns wr
     ON ws.ws_order_number = wr.wr_order_number
   WHERE p.p_channel_dmail = 'Y'
     AND ca.ca_state = 'CA'
     AND wsite.web_market_manager = 'William Reyes'
),

agg1 AS (
   SELECT
      ws_web_site_sk,
      ws_ship_mode_sk,
      ws_web_page_sk,
      ws_promo_sk,
      SUM(ws_net_paid) AS total_paid,
      SUM(COALESCE(wr_return_amt, 0)) AS total_return,
      COUNT(*) AS sales_cnt
   FROM sales_base
   GROUP BY ws_web_site_sk, ws_ship_mode_sk, ws_web_page_sk, ws_promo_sk
),

page_stats AS (
   SELECT
      wp_web_page_sk,
      SUM(wp_char_count) AS total_chars,
      AVG(wp_max_ad_count) AS avg_ad_count
   FROM web_page
   GROUP BY wp_web_page_sk
),

full_joined AS (
   SELECT
      COALESCE(a.ws_web_page_sk, p.wp_web_page_sk) AS page_sk,
      a.ws_web_site_sk,
      a.ws_ship_mode_sk,
      a.ws_promo_sk,
      a.total_paid,
      a.total_return,
      p.total_chars,
      p.avg_ad_count
   FROM agg1 a
   FULL OUTER JOIN page_stats p
     ON a.ws_web_page_sk = p.wp_web_page_sk
),

high_profit_sites AS (
   SELECT ws_web_site_sk
   FROM agg1
   WHERE total_paid - total_return > 10000
   GROUP BY ws_web_site_sk
),

low_profit_sites AS (
   SELECT ws_web_site_sk
   FROM agg1
   WHERE total_paid - total_return < 2000
   GROUP BY ws_web_site_sk
),

union_sites AS (
   SELECT DISTINCT ws_web_site_sk FROM high_profit_sites
   UNION
   SELECT DISTINCT ws_web_site_sk FROM low_profit_sites
),

exclusive_high AS (
   SELECT ws_web_site_sk FROM high_profit_sites
   EXCEPT
   SELECT ws_web_site_sk FROM low_profit_sites
),

intersect_sites AS (
   SELECT ws_web_site_sk FROM high_profit_sites
   INTERSECT
   SELECT ws_web_site_sk FROM low_profit_sites
)

SELECT DISTINCT
   fj.page_sk,
   fj.ws_web_site_sk,
   fj.ws_ship_mode_sk,
   fj.total_paid,
   fj.total_return,
   fj.total_chars,
   fj.avg_ad_count
FROM full_joined fj
WHERE EXISTS (
   SELECT 1
   FROM promotion p2
   WHERE p2.p_promo_sk = fj.ws_promo_sk
     AND p2.p_discount_active = 'Y'
)
  AND fj.total_paid > 5000
  AND (fj.total_chars IS NULL OR fj.total_chars > 1000)
ORDER BY fj.total_paid DESC
LIMIT 100
