<?php
namespace OPNsense\FirewallMap;

/** Plugin-owned messages. Never change the system gettext domain or user data. */
class Translation
{
    private $language;
    private $messages;

    public function __construct($language = null)
    {
        $this->language = $language;
        $this->messages = json_decode(file_get_contents(__DIR__ . '/I18n/zh_CN.json'), true) ?: [];
    }

    public function isChinese()
    {
        $locale = $this->language ?? setlocale(LC_MESSAGES, 0);
        return preg_match('/^zh(?:[_-](?:CN|Hans))(?:[_.@-].*)?$/i', (string)$locale) === 1;
    }

    public function translate($message)
    {
        if ($this->isChinese() && isset($this->messages[$message])) {
            return $this->messages[$message];
        }
        return gettext($message);
    }

    /** Same escaping contract as OPNsense's lang._(), including use inside JS JSON strings. */
    public function _($message)
    {
        return htmlspecialchars($this->translate($message), ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
    }

    /** Only display labels are translated. IDs, option keys, stored values and secrets stay intact. */
    public function form($form)
    {
        if (!is_array($form)) {
            return $form;
        }
        foreach ($form as $key => $value) {
            if (is_array($value)) {
                $form[$key] = $this->form($value);
            } elseif (is_string($value) && (in_array($key, ['label', 'help', 'hint', 'tab_descr', 'optgroup'])
                || ($key === 'value' && array_key_exists('selected', $form)))) {
                $form[$key] = $this->translate($value);
            }
        }
        return $form;
    }
}
