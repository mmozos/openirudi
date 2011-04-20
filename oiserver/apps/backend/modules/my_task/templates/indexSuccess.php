<?php use_helper('I18N', 'Date') ?>
<?php include_partial('my_task/assets') ?>
<?php include_partial('global/filter_js') ?>

<div id="sf_admin_container">
  <h1 style="float:left"><?php echo __('My task List', array(), 'messages') ?></h1>
  <input id="click_filter" value="<?php echo __('Search', array(), 'messages'); ?>" type="button"  style="float:right" />

  <div class="list_notice">
  	<?php include_partial('my_task/flashes') ?>
  </div>

  <div id="sf_admin_header">
    <?php include_partial('my_task/list_header', array('pager' => $pager)) ?>
  </div>

  <!--
  <div id="sf_admin_bar">
  -->
  <div id="show_filter">
    <?php include_partial('my_task/filters', array('form' => $filters, 'configuration' => $configuration)) ?>
  </div>

  <div id="sf_admin_content">   
    <?php include_partial('my_task/list', array('pager' => $pager, 'sort' => $sort, 'helper' => $helper)) ?>    
    <ul class="sf_admin_actions">
      <?php include_partial('my_task/list_batch_actions', array('helper' => $helper)) ?>
      <?php include_partial('my_task/list_actions', array('helper' => $helper)) ?>
    </ul>
  </div>

  <div id="sf_admin_footer">
    <?php include_partial('my_task/list_footer', array('pager' => $pager)) ?>
  </div>
</div>
