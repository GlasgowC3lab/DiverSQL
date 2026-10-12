SELECT
    ca.d_year,
    ca.d_month_seq,
    ca.sm_type,
    ca.hd_buy_potential,
    ca.catalog_net_loss,
    wa.web_net_loss,
    ca.catalog_return_qty + wa.web_return_qty AS total_return_qty,
    ca.avg_store_credit,
    wa.avg_fee,
    ca.distinct_catalog_items,
    wa.distinct_web_items
FROM (
    SELECT
        d.d_year,
        d.d_month_seq,
        sm.sm_type,
        hd.hd_buy_potential,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(cr.cr_return_quantity) AS catalog_return_qty,
        AVG(cr.cr_store_credit) AS avg_store_credit,
        COUNT(DISTINCT cr.cr_item_sk) AS distinct_catalog_items
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND sm.sm_type IN ('AIR', 'GROUND')
      AND hd.hd_buy_potential = 'HIGH'
    GROUP BY
        d.d_year,
        d.d_month_seq,
        sm.sm_type,
        hd.hd_buy_potential
) ca
LEFT JOIN (
    SELECT
        d.d_year,
        d.d_month_seq,
        hd.hd_buy_potential,
        SUM(wr.wr_net_loss) AS web_net_loss,
        SUM(wr.wr_return_quantity) AS web_return_qty,
        AVG(wr.wr_fee) AS avg_fee,
        COUNT(DISTINCT wr.wr_item_sk) AS distinct_web_items
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND hd.hd_buy_potential = 'HIGH'
    GROUP BY
        d.d_year,
        d.d_month_seq,
        hd.hd_buy_potential
) wa
    ON ca.d_year = wa.d_year
   AND ca.d_month_seq = wa.d_month_seq
   AND ca.hd_buy_potential = wa.hd_buy_potential
WHERE ca.catalog_net_loss > 10000
ORDER BY ca.catalog_net_loss DESC
LIMIT 100
