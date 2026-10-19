<?php
namespace OPNsense\FirewallMap;

/** The existing core log API and its privileges are reused; raw logs are never rewritten. */
class LogController extends UiController
{
    public function indexAction()
    {
        $this->view->title = (new Translation())->translate('Firewall Map');
        $this->view->module = 'core';
        $this->view->scope = 'firewallmap';
        $this->view->service = '';
        $this->view->default_log_severity = 'Informational';
        $this->view->pick('OPNsense/FirewallMap/log');
    }
}
