<?php

/**
 * device module helper.
 *
 * @package    drivers
 * @subpackage device
 * @author     Your name here
 * @version    SVN: $Id: helper.php 12474 2008-10-31 10:41:27Z fabien $
 */
class deviceGeneratorHelper extends BaseDeviceGeneratorHelper {

    public function linkToView($object, $params) {
        return '<li class="sf_admin_action_view">'.link_to(__($params['label'], array(), 'sf_admin'), 'device/view?id='.$object->getId()).'</li>';
    }
    //kam
    public function linkToEdit($object, $params)
    {
      return '<li class="sf_admin_action_edit">'.link_to(__($params['label'], array(), 'sf_admin'), 'device/edit?id='.$object->getId()).'</li>';
    }
    //kam
    public function linkToDelete($object, $params)
    {
      if ($object->isNew())
      {
        return '';
      }

      return '<li class="sf_admin_action_delete">'.link_to(__($params['label'], array(), 'sf_admin'), 'device/delete?id='.$object->getId(), array('method' => 'delete', 'confirm' => !empty($params['confirm']) ? __($params['confirm'], array(), 'sf_admin') : $params['confirm'])).'</li>';
    }
}
