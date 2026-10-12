WITH filtered_returns AS (
   SELECT
       cr.cr_returned_date_sk,
       cr.cr_return_amount,
       cr.cr_return_quantity,
       cr.cr_net_loss,
       cr.cr_catalog_page_sk,
       cr.cr_returning_addr_sk,
       cr.cr_returning_hdemo_sk,
       cr.cr_refunded_addr_sk,
       cr.cr_refunded_hdemo_sk
   FROM catalog_returns cr
   WHERE cr.cr_returned_date_sk BETWEEN 2450800 AND 2451200
),
page_info AS (
   SELECT
       cp.cp_catalog_page_sk,
       cp.cp_department,
       cp.cp_type,
       cp.cp_catalog_page_number
   FROM catalog_page cp
   WHERE cp.cp_catalog_page_number IN (1,2,3)
)
SELECT
   agg.cp_department,
   agg.cp_type,
   agg.cp_catalog_page_number,
   agg.ret_state,
   agg.ref_state,
   agg.hd_buy_potential,
   agg.total_return_amount,
   agg.total_return_qty,
   agg.avg_return_amount,
   agg.total_net_loss,
   agg.loss_ratio,
   agg.same_state_count,
   RANK() OVER (PARTITION BY agg.cp_department ORDER BY agg.total_return_amount DESC) AS dept_page_rank,
   agg.total_return_amount - LAG(agg.total_return_amount) OVER (PARTITION BY agg.cp_department ORDER BY agg.cp_catalog_page_number) AS diff_prev_page
FROM (
   SELECT
       pi.cp_department,
       pi.cp_type,
       pi.cp_catalog_page_number,
       ca_ret.ca_state AS ret_state,
       ca_ref.ca_state AS ref_state,
       hd_ret.hd_buy_potential,
       SUM(fr.cr_return_amount) AS total_return_amount,
       SUM(fr.cr_return_quantity) AS total_return_qty,
       AVG(fr.cr_return_amount) AS avg_return_amount,
       SUM(fr.cr_net_loss) AS total_net_loss,
       ROUND(SUM(fr.cr_net_loss) / NULLIF(SUM(fr.cr_return_amount),0), 2) AS loss_ratio,
       SUM(CASE WHEN ca_ret.ca_state = ca_ref.ca_state THEN 1 ELSE 0 END) AS same_state_count
   FROM filtered_returns fr
   JOIN page_info pi ON fr.cr_catalog_page_sk = pi.cp_catalog_page_sk
   JOIN customer_address ca_ret ON fr.cr_returning_addr_sk = ca_ret.ca_address_sk
   JOIN household_demographics hd_ret ON fr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
   JOIN customer_address ca_ref ON fr.cr_refunded_addr_sk = ca_ref.ca_address_sk
   JOIN household_demographics hd_ref ON fr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
   GROUP BY pi.cp_department, pi.cp_type, pi.cp_catalog_page_number, ca_ret.ca_state, ca_ref.ca_state, hd_ret.hd_buy_potential
   HAVING SUM(fr.cr_return_amount) > 500
) agg
ORDER BY agg.total_return_amount DESC
LIMIT 50
