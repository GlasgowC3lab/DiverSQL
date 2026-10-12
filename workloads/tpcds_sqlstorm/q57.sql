WITH cat_sales AS (
   SELECT
      p.p_promo_id,
      d.d_quarter_seq,
      d.d_quarter_name,
      SUM(cs.cs_net_profit) AS cat_profit,
      SUM(cs.cs_net_paid) AS cat_net_paid,
      COUNT(*) AS cat_order_cnt
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE d.d_year = 2000
   GROUP BY p.p_promo_id, d.d_quarter_seq, d.d_quarter_name
),
store_sales AS (
   SELECT
      p.p_promo_id,
      d.d_quarter_seq,
      d.d_quarter_name,
      SUM(ss.ss_net_profit) AS store_profit,
      SUM(ss.ss_net_paid) AS store_net_paid,
      COUNT(*) AS store_order_cnt
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE d.d_year = 2000
   GROUP BY p.p_promo_id, d.d_quarter_seq, d.d_quarter_name
),
web_sales AS (
   SELECT
      p.p_promo_id,
      d.d_quarter_seq,
      d.d_quarter_name,
      SUM(ws.ws_net_profit) AS web_profit,
      SUM(ws.ws_net_paid) AS web_net_paid,
      COUNT(*) AS web_order_cnt
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   WHERE d.d_year = 2000
   GROUP BY p.p_promo_id, d.d_quarter_seq, d.d_quarter_name
),
combined AS (
   SELECT
      COALESCE(c.p_promo_id, s.p_promo_id, w.p_promo_id) AS promo_id,
      COALESCE(c.d_quarter_seq, s.d_quarter_seq, w.d_quarter_seq) AS quarter_seq,
      COALESCE(c.d_quarter_name, s.d_quarter_name, w.d_quarter_name) AS quarter_name,
      COALESCE(c.cat_profit, 0) AS cat_profit,
      COALESCE(s.store_profit, 0) AS store_profit,
      COALESCE(w.web_profit, 0) AS web_profit,
      COALESCE(c.cat_net_paid, 0) AS cat_net_paid,
      COALESCE(s.store_net_paid, 0) AS store_net_paid,
      COALESCE(w.web_net_paid, 0) AS web_net_paid,
      COALESCE(c.cat_order_cnt, 0) AS cat_order_cnt,
      COALESCE(s.store_order_cnt, 0) AS store_order_cnt,
      COALESCE(w.web_order_cnt, 0) AS web_order_cnt
   FROM cat_sales c
   FULL OUTER JOIN store_sales s
      ON c.p_promo_id = s.p_promo_id AND c.d_quarter_seq = s.d_quarter_seq
   FULL OUTER JOIN web_sales w
      ON COALESCE(c.p_promo_id, s.p_promo_id) = w.p_promo_id
     AND COALESCE(c.d_quarter_seq, s.d_quarter_seq) = w.d_quarter_seq
),
aggregated AS (
   SELECT
      promo_id,
      quarter_seq,
      quarter_name,
      cat_profit,
      store_profit,
      web_profit,
      cat_profit + store_profit + web_profit AS total_profit,
      cat_net_paid + store_net_paid + web_net_paid AS total_net_paid,
      cat_order_cnt + store_order_cnt + web_order_cnt AS total_orders,
      CASE WHEN cat_profit + store_profit + web_profit = 0 THEN 0
           ELSE cat_profit / (cat_profit + store_profit + web_profit) END AS cat_profit_pct,
      CASE WHEN cat_profit + store_profit + web_profit = 0 THEN 0
           ELSE store_profit / (cat_profit + store_profit + web_profit) END AS store_profit_pct,
      CASE WHEN cat_profit + store_profit + web_profit = 0 THEN 0
           ELSE web_profit / (cat_profit + store_profit + web_profit) END AS web_profit_pct,
      ROW_NUMBER() OVER (PARTITION BY quarter_seq ORDER BY (cat_profit + store_profit + web_profit) DESC) AS rank_in_quarter
   FROM combined
)
SELECT
   promo_id,
   quarter_name,
   quarter_seq,
   total_profit,
   total_net_paid,
   total_orders,
   cat_profit,
   store_profit,
   web_profit,
   cat_profit_pct,
   store_profit_pct,
   web_profit_pct,
   rank_in_quarter
FROM aggregated
WHERE rank_in_quarter <= 10
ORDER BY quarter_seq, rank_in_quarter
