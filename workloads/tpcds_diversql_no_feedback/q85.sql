WITH
  agg_store_sales AS (
    SELECT
      ss_store_sk,
      ss_sold_time_sk,
      SUM(ss_net_paid) AS total_store_net,
      SUM(ss_quantity) AS total_store_qty
    FROM store_sales
    GROUP BY ss_store_sk, ss_sold_time_sk
  ),
  agg_web_sales AS (
    SELECT
      ws_web_site_sk,
      ws_sold_time_sk,
      SUM(ws_net_paid) AS total_web_net,
      COUNT(*) AS web_orders
    FROM web_sales
    GROUP BY ws_web_site_sk, ws_sold_time_sk
  ),
  store_base AS (
    SELECT
      s.s_store_sk,
      s.s_store_id,
      s.s_state,
      s.s_zip
    FROM store s
  ),
  catalog_base AS (
    SELECT
      cs.cs_order_number,
      cs.cs_call_center_sk,
      cs.cs_sold_time_sk,
      cs.cs_bill_customer_sk,
      cs.cs_bill_cdemo_sk,
      cs.cs_net_paid
    FROM catalog_sales cs
  ),
  web_site_base AS (
    SELECT
      ws.web_site_sk,
      ws.web_name
    FROM web_site ws
  ),
  sub_a AS (
    SELECT
      sb.s_store_sk,
      sb.s_store_id,
      agg_ss.total_store_net,
      agg_ws.total_web_net,
      td_s.t_hour        AS store_hour,
      td_w.t_hour        AS web_hour,
      CASE WHEN agg_ss.total_store_net > agg_ws.total_web_net THEN 'Store' ELSE 'Web' END AS top_source
    FROM store_base sb
    JOIN agg_store_sales agg_ss ON agg_ss.ss_store_sk = sb.s_store_sk
    JOIN time_dim td_s       ON agg_ss.ss_sold_time_sk = td_s.t_time_sk
    JOIN agg_web_sales agg_ws ON 1 = 1
    JOIN time_dim td_w       ON agg_ws.ws_sold_time_sk = td_w.t_time_sk
    JOIN web_site_base wsb   ON wsb.web_site_sk = agg_ws.ws_web_site_sk
    WHERE sb.s_state = 'CA'
  ),
  sub_b AS (
    SELECT
      sb.s_store_sk,
      sb.s_store_id,
      agg_ss.total_store_net,
      agg_ws.total_web_net,
      td_s.t_hour        AS store_hour,
      td_w.t_hour        AS web_hour,
      CASE WHEN agg_ss.total_store_net > agg_ws.total_web_net THEN 'Store' ELSE 'Web' END AS top_source
    FROM store_base sb
    JOIN agg_store_sales agg_ss ON agg_ss.ss_store_sk = sb.s_store_sk
    JOIN time_dim td_s       ON agg_ss.ss_sold_time_sk = td_s.t_time_sk
    JOIN agg_web_sales agg_ws ON 1 = 1
    JOIN time_dim td_w       ON agg_ws.ws_sold_time_sk = td_w.t_time_sk
    JOIN web_site_base wsb   ON wsb.web_site_sk = agg_ws.ws_web_site_sk
    WHERE sb.s_state = 'TX'
  ),
  union_sub AS (
    SELECT * FROM sub_a
    UNION
    SELECT * FROM sub_b
  ),
  intersect_keys AS (
    SELECT sb.s_store_sk
    FROM store_base sb
    JOIN store_returns sr ON sr.sr_store_sk = sb.s_store_sk
    JOIN customer c      ON c.c_customer_sk = sr.sr_customer_sk
    JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE sr.sr_return_quantity > 0
    INTERSECT
    SELECT cs.cs_bill_customer_sk
    FROM catalog_base cs
    JOIN call_center cc ON cc.cc_call_center_sk = cs.cs_call_center_sk
    JOIN customer c2    ON c2.c_customer_sk = cs.cs_bill_customer_sk
    JOIN customer_demographics cd2 ON cd2.cd_demo_sk = c2.c_current_cdemo_sk
    WHERE cc.cc_tax_percentage > 0
  ),
  final AS (
    SELECT
      us.s_store_id,
      us.total_store_net,
      us.total_web_net,
      us.top_source,
      ROW_NUMBER() OVER (ORDER BY us.total_store_net DESC) AS rn
    FROM union_sub us
    JOIN intersect_keys ik ON us.s_store_sk = ik.s_store_sk
  )
SELECT *
FROM final
LIMIT 100
