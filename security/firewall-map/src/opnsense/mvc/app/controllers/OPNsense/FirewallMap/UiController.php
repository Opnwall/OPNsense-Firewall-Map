<?php
namespace OPNsense\FirewallMap;

/** Localization is scoped to this plugin; core pages and catalogs are untouched. */
abstract class UiController extends \OPNsense\Base\IndexController
{
    public function __construct()
    {
        parent::__construct();
        $this->view->fwlang = new Translation();
    }

    public function getForm($formname)
    {
        return (new Translation())->form(parent::getForm($formname));
    }

    public function getFormGrid($formname, $grid_id = null, $root = null)
    {
        return (new Translation())->form(parent::getFormGrid($formname, $grid_id, $root));
    }
}
