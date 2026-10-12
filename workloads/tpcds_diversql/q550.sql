WITH
  sr_agg AS (
    SELECT
      sr.sr_store_sk,
      d_ret.d_year,
      SUM(sr.sr_net_loss) AS total_store_net_loss,
      COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret ON sr.sr_return_time_sk = t_ret.t_time_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d_ret.d_year = 2002
      AND cd.cd_education_status = 'College'
      AND ca.ca_state = 'CA'
      AND t_ret.t_hour BETWEEN 9 AND 17
    GROUP BY sr.sr_store_sk, d_ret.d_year
  ),
  cr_agg AS (
    SELECT
      cr.cr_ship_mode_sk,
      d_ret2.d_year,
      SUM(cr.cr_net_loss) AS total_catalog_net_loss,
      COUNT(*) AS catalog_return_cnt
    FROM catalog_returns cr
    JOIN date_dim d_ret2 ON cr.cr_returned_date_sk = d_ret2.d_date_sk
    JOIN time_dim t_ret2 ON cr.cr_returned_time_sk = t_ret2.t_time_sk
    JOIN customer_demographics cd2 ON cr.cr_refunded_cdemo_sk = cd2.cd_demo_sk
    JOIN customer_address ca2 ON cr.cr_refunded_addr_sk = ca2.ca_address_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r2 ON cr.cr_reason_sk = r2.r_reason_sk
    WHERE d_ret2.d_year = 2002
      AND sm.sm_type = 'AIR'
      AND cd2.cd_purchase_estimate > 5000
    GROUP BY cr.cr_ship_mode_sk, d_ret2.d_year
  ),
  date_start AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2002
      AND d_month_seq = 1
  ),
  store_keys AS (
    SELECT s_store_sk FROM store
  ),
  store_return_keys AS (
    SELECT sr_store_sk FROM store_returns
  ),
  stores_without_returns AS (
    SELECT s_store_sk FROM store_keys
    EXCEPT
    SELECT sr_store_sk FROM store_return_keys
  ),
  final AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      sr_agg.d_year,
      sr_agg.total_store_net_loss,
      sr_agg.store_return_cnt,
      cr_agg.total_catalog_net_loss,
      cr_agg.catalog_return_cnt,
      p.p_promo_name,
      ws.web_name,
      lat.avg_return_net_loss
    FROM store s
    JOIN sr_agg ON s.s_store_sk = sr_agg.sr_store_sk
    JOIN cr_agg ON sr_agg.d_year = cr_agg.d_year
    JOIN date_start ds ON TRUE
    JOIN promotion p ON p.p_start_date_sk = ds.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = ds.d_date_sk
    LEFT JOIN LATERAL (
      SELECT AVG(sr2.sr_net_loss) AS avg_return_net_loss
      FROM store_returns sr2
      WHERE sr2.sr_store_sk = s.s_store_sk
    ) AS lat ON TRUE
    WHERE NOT EXISTS (
      SELECT 1 FROM stores_without_returns swr
      WHERE swr.s_store_sk = s.s_store_sk
    )
      AND p.p_discount_active = 'Y'
      AND ws.web_state = 'CA'
  )
SELECT *
FROM final
ORDER BY total_store_net_loss DESC
LIMIT 100
