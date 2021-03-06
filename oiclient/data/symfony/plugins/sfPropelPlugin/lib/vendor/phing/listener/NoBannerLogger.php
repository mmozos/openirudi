<?php
/*
 * $Id: NoBannerLogger.php 3076 2006-12-18 08:52:12Z fabien $
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * This software consists of voluntary contributions made by many individuals
 * and is licensed under the LGPL. For more information please see
 * <http://phing.info>.
 */

include_once 'phing/listener/DefaultLogger.php';

/**
 *  Extends DefaultLogger to strip out empty targets.  This logger is most
 *  commonly used and also enforced by the default phing invokation scripts
 *  in bin/.
 *
 *  @author    Andreas Aderhold <andi@binarycloud.com>
 *  @copyright ? 2001,2002 THYRELL. All rights reserved
 *  @version   $Revision: 1.4 $ $Date: 2003/12/24 13:02:08 $
 *  @package   phing.listener
 */
class NoBannerLogger extends DefaultLogger {

    private $targetName = null;

    function targetStarted(BuildEvent $event) {
        $target = $event->getTarget();
        $this->targetName = $target->getName();
    }

    function targetFinished(BuildEvent $event) {
        $this->targetName = null;
    }

    function messageLogged(BuildEvent $event) {
        if ($event->getPriority() > $this->msgOutputLevel ||
                null === $event->getMessage() ||
                         trim($event->getMessage() === "")) {
            return;
        }

        if ($this->targetName !== null) {
            print($this->lSep . "Target: ".$this->targetName . $this->lSep);
            $this->targetName = null;
        }

        parent::messageLogged($event);
    }
}
