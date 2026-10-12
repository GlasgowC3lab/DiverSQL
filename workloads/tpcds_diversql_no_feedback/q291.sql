WITH base_sales AS (
   SELECT
      ss.ss_ticket_number,
      ss.ss_sales_price,
      ss.ss_net_profit,
      ss.ss_wholesale_cost,
      i.i_color,
      i.i_manufact_id,
      c.c_birth_year,
      wp.wp_link_count
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
   WHERE i.i_color IN ('papaya','lime')
     AND i.i_manufact_id IN (294,625)
     AND ss.ss_wholesale_cost > 50
),
returns_sum AS (
   SELECT
      sr.sr_ticket_number,
      SUM(sr.sr_return_amt) AS total_return_amt
   FROM store_returns sr
   GROUP BY sr.sr_ticket_number
),
joined AS (
   SELECT
      bs.ss_ticket_number,
      bs.ss_sales_price,
      bs.ss_net_profit,
      bs.ss_wholesale_cost,
      bs.c_birth_year,
      bs.wp_link_count,
      COALESCE(rs.total_return_amt, 0) AS total_return_amt
   FROM base_sales bs
   LEFT JOIN returns_sum rs ON bs.ss_ticket_number = rs.sr_ticket_number
),
union_set AS (
   SELECT
      ss_ticket_number,
      ss_sales_price - total_return_amt AS net_rev,
      ss_net_profit
   FROM joined
   WHERE (ss_sales_price - total_return_amt) > 100
   UNION
   SELECT
      ss_ticket_number,
      ss_sales_price - total_return_amt AS net_rev,
      ss_net_profit
   FROM joined
   WHERE ss_net_profit < 0
),
 ticket_ex AS (
   SELECT ss_ticket_number FROM union_set
   EXCEPT
   SELECT ss_ticket_number FROM joined WHERE ss_net_profit > 500
 ),
 final AS (
   SELECT
      AVG(net_rev) AS avg_net_rev,
      COUNT(*) AS ticket_cnt
   FROM union_set u
   JOIN ticket_ex te ON u.ss_ticket_number = te.ss_ticket_number
 )
SELECT avg_net_rev, ticket_cnt
FROM final
ORDER BY avg_net_rev DESC
LIMIT 100
