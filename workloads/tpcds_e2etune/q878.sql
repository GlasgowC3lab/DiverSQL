WITH agg AS (
   SELECT
      cc.cc_name AS cc_name,
      cc.cc_state AS cc_state,
      d.d_year AS d_year,
      d.d_month_seq AS d_month_seq,
      i.i_category AS i_category,
      SUM(cr.cr_net_loss) AS total_net_loss,
      SUM(cr.cr_return_quantity) AS total_return_qty,
      AVG(cr.cr_return_amount) AS avg_return_amount
   FROM catalog_returns cr
   JOIN call_center cc
     ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN date_dim d
     ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN time_dim t
     ON cr.cr_returned_time_sk = t.t_time_sk
   JOIN item i
     ON cr.cr_item_sk = i.i_item_sk
   JOIN catalog_page cp
     ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   LEFT JOIN store s
     ON d.d_date_sk = s.s_closed_date_sk
   WHERE cr.cr_net_loss > 0
     AND cc.cc_state IN ('TN', 'LA', 'GA')
     AND cc.cc_mkt_id IN (2, 3, 4)
     AND d.d_year = 2001
     AND t.t_hour BETWEEN 8 AND 20
     AND cp.cp_department = 'Electronics'
   GROUP BY
      cc.cc_name,
      cc.cc_state,
      d.d_year,
      d.d_month_seq,
      i.i_category
)
SELECT
   agg.cc_name,
   agg.cc_state,
   agg.d_year,
   agg.d_month_seq,
   agg.i_category,
   agg.total_net_loss,
   agg.total_return_qty,
   agg.avg_return_amount,
   RANK() OVER (PARTITION BY agg.d_year, agg.d_month_seq ORDER BY agg.total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY
   agg.d_year,
   agg.d_month_seq,
   agg.total_net_loss DESC
LIMIT 200
