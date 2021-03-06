<?php

/**
 * sfPropelAdminGeneratorWithShowPlugin configuration.
 * 
 * @package     sfPropelAdminGeneratorWithShowPlugin
 * @subpackage  config
 * @author      Your name here
 * @version     SVN: $Id: PluginConfiguration.class.php 12675 2008-11-06 08:07:42Z Kris.Wallsmith $
 */
class sfPropelAdminGeneratorWithShowPluginConfiguration extends sfPluginConfiguration
{
  /**
   * @see sfPluginConfiguration
   */
  public function initialize()
  {
    if(!in_array('sfPropelPlugin',$this->configuration->getPlugins()))
    {
      throw new sfException('sfPropelAdminGeneratorWithShowPlugin require sfPropelPlugin.');
    }
  }
}
