WITH daily_store AS (
    SELECT d.d_date_sk,
           d.d_year,
           d.d_month_seq,
           SUM(sr.sr_net_loss) AS store_net_loss
    FROM date_dim d
    LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk, d.d_year, d.d_month_seq
),

daily_catalog AS (
    SELECT d.d_date_sk,
           SUM(cr.cr_net_loss) AS catalog_net_loss
    FROM date_dim d
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk
),

daily_web AS (
    SELECT d.d_date_sk,
           SUM(wr.wr_net_loss) AS web_net_loss
    FROM date_dim d
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk
),

daily_inventory AS (
    SELECT d.d_date_sk,
           SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM date_dim d
    LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk
),

daily_catalog_pages AS (
    SELECT d.d_date_sk,
           COUNT(DISTINCT cp.cp_catalog_page_id) AS pages_ended
    FROM date_dim d
    LEFT JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk
),

daily_websites AS (
    SELECT d.d_date_sk,
           COUNT(DISTINCT ws.web_site_id) AS sites_opened
    FROM date_dim d
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk
)
SELECT
    ds.d_year,
    ds.d_month_seq,
    SUM(ds.store_net_loss) AS total_store_net_loss,
    SUM(dc.catalog_net_loss) AS total_catalog_net_loss,
    SUM(dw.web_net_loss) AS total_web_net_loss,
    SUM(di.total_quantity) AS total_inventory_quantity,
    SUM(dcp.pages_ended) AS catalog_pages_ended,
    SUM(dws.sites_opened) AS websites_opened,
    RANK() OVER (ORDER BY (SUM(ds.store_net_loss) + SUM(dc.catalog_net_loss) + SUM(dw.web_net_loss)) DESC) AS loss_rank
FROM daily_store ds
LEFT JOIN daily_catalog dc ON dc.d_date_sk = ds.d_date_sk
LEFT JOIN daily_web dw ON dw.d_date_sk = ds.d_date_sk
LEFT JOIN daily_inventory di ON di.d_date_sk = ds.d_date_sk
LEFT JOIN daily_catalog_pages dcp ON dcp.d_date_sk = ds.d_date_sk
LEFT JOIN daily_websites dws ON dws.d_date_sk = ds.d_date_sk
WHERE ds.d_year BETWEEN 1998 AND 2000
GROUP BY ds.d_year, ds.d_month_seq
ORDER BY total_store_net_loss DESC
LIMIT 50
