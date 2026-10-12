WITH ss_sample AS (
   SELECT *
   FROM store_sales
   TABLESAMPLE BERNOULLI (10)
),
base_join AS (
   SELECT
      ss.ss_ticket_number               AS ticket_number,
      ss.ss_net_profit                  AS net_profit,
      d.d_year                          AS year,
      t.t_hour                          AS hour_of_day,
      c.c_first_name                    AS first_name,
      c.c_last_name                     AS last_name,
      ca.ca_state                       AS state,
      cd.cd_gender                      AS gender,
      ib.ib_upper_bound                 AS income_upper_bound,
      p.p_promo_name                    AS promo_name,
      s.s_store_name                    AS store_name,
      ws.ws_order_number                AS order_number,
      ws.ws_net_profit                  AS ws_net_profit,
      sm.sm_code                        AS ship_mode_code,
      r.r_reason_desc                   AS return_reason,
      we.web_name                       AS website_name
   FROM ss_sample ss
   JOIN date_dim d      ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN time_dim t      ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN customer c      ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib   ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN promotion p      ON ss.ss_promo_sk = p.p_promo_sk
   JOIN store s          ON ss.ss_store_sk = s.s_store_sk
   JOIN web_sales ws    ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN ship_mode sm    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN web_returns wr  ON wr.wr_order_number = ws.ws_order_number
   JOIN reason r        ON wr.wr_reason_sk = r.r_reason_sk
   JOIN web_site we     ON ws.ws_web_site_sk = we.web_site_sk
   WHERE d.d_year = 2001
     AND ca.ca_state = 'CA'
     AND ib.ib_upper_bound >= 70000
     AND p.p_discount_active = 'N'
     AND sm.sm_code = 'AIR'
     AND NOT EXISTS (
         SELECT 1
         FROM promotion p2
         WHERE p2.p_promo_sk = ss.ss_promo_sk
           AND p2.p_discount_active = 'Y'
     )
),
union_set AS (
   SELECT DISTINCT ticket_number AS ticket, net_profit AS profit, year
   FROM base_join
   UNION
   SELECT DISTINCT order_number AS ticket, ws_net_profit AS profit, year
   FROM base_join
),
intersect_set AS (
   SELECT ws.ws_order_number AS order_num
   FROM web_sales ws
   INTERSECT
   SELECT wr.wr_order_number AS order_num
   FROM web_returns wr
),
cross_part AS (
   SELECT v.val, d.d_month_seq
   FROM (VALUES 1, 2, 3) AS v(val)
   CROSS JOIN (
       SELECT d_month_seq
       FROM date_dim
       WHERE d_year = 2001
       LIMIT 5
   ) d
),
final AS (
   SELECT
      bj.ticket_number,
      bj.net_profit,
      bj.year,
      bj.first_name,
      bj.last_name,
      bj.state,
      ROW_NUMBER() OVER (PARTITION BY bj.store_name ORDER BY bj.net_profit DESC) AS rn,
      RANK()       OVER (ORDER BY bj.net_profit DESC)               AS rnk
   FROM base_join bj
   WHERE bj.ticket_number IN (SELECT order_num FROM intersect_set)
     AND EXISTS (
         SELECT 1
         FROM cross_part cp
         WHERE cp.val = 2
     )
)
SELECT *
FROM final
ORDER BY rnk ASC, rn ASC
LIMIT 100
