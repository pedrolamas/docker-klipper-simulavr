# Virtual Pins support
#
# Copyright (C) 2022  Pedro Lamas <pedrolamas@gmail.com>
#
# This file may be distributed under the terms of the GNU GPLv3 license.

class VirtualPins:
    def __init__(self, config):
        self._printer = config.get_printer()
        ppins = self._printer.lookup_object('pins')
        ppins.register_chip('virtual_pin', self)
        self._pins = {}

    def setup_pin(self, pin_type, pin_params):
        ppins = self._printer.lookup_object('pins')
        name = pin_params['pin']
        if name in self._pins:
            return self._pins[name]
        if pin_type == 'digital_out':
            pin = DigitalOutVirtualPin(self, pin_params)
        elif pin_type == 'pwm':
            pin = PwmVirtualPin(self, pin_params)
        elif pin_type == 'adc':
            pin = AdcVirtualPin(self, pin_params)
        elif pin_type == 'endstop':
            pin = EndstopVirtualPin(self, pin_params)
        else:
            raise ppins.error("unable to create virtual pin of type %s" % (
                pin_type,))
        self._pins[name] = pin
        return pin

    def get_printer(self):
        return self._printer

    def get_status(self, eventtime):
        return {
            'pins': {
                name : pin.get_status(eventtime)
                    for name, pin in self._pins.items()
            }
        }

class VirtualPin:
    def __init__(self, mcu, pin_params):
        self._mcu = mcu
        self._name = pin_params['pin']
        self._pullup = pin_params['pullup']
        self._invert = pin_params['invert']
        self._value = self._pullup
        printer = self._mcu.get_printer()
        self._real_mcu = printer.lookup_object('mcu')
        gcode = printer.lookup_object('gcode')
        gcode.register_mux_command("SET_VIRTUAL_PIN", "PIN", self._name,
                                   self.cmd_SET_VIRTUAL_PIN,
                                   desc=self.cmd_SET_VIRTUAL_PIN_help)

    cmd_SET_VIRTUAL_PIN_help = "Set the value of an output pin"
    def cmd_SET_VIRTUAL_PIN(self, gcmd):
        self._value = gcmd.get_float('VALUE', minval=0., maxval=1.)

    def get_mcu(self):
        return self._real_mcu

class DigitalOutVirtualPin(VirtualPin):
    def __init__(self, mcu, pin_params):
        VirtualPin.__init__(self, mcu, pin_params)

    def setup_max_duration(self, max_duration):
        pass

    def setup_start_value(self, start_value, shutdown_value):
        self._value = start_value

    def set_digital(self, print_time, value):
        self._value = value

    def get_status(self, eventtime):
        return {
            'value': self._value,
            'type': 'digital_out'
        }

class PwmVirtualPin(VirtualPin):
    def __init__(self, mcu, pin_params):
        VirtualPin.__init__(self, mcu, pin_params)

    def setup_max_duration(self, max_duration):
        pass

    def setup_start_value(self, start_value, shutdown_value):
        self._value = start_value

    def setup_cycle_time(self, cycle_time, hardware_pwm=False):
        pass

    def set_pwm(self, print_time, value, cycle_time=None):
        self._value = value

    def get_status(self, eventtime):
        return {
            'value': self._value,
            'type': 'pwm'
        }

class AdcVirtualPin(VirtualPin):
    def __init__(self, mcu, pin_params):
        VirtualPin.__init__(self, mcu, pin_params)
        self._callback = None
        self._min_sample = 0.
        self._max_sample = 0.
        printer = self._mcu.get_printer()
        printer.register_event_handler("klippy:connect",
                                            self.handle_connect)

    def handle_connect(self):
        reactor = self._mcu.get_printer().get_reactor()
        reactor.register_timer(self._raise_callback, reactor.NOW)

    def setup_adc_callback(self, report_time, callback):
        self._callback = callback

    def setup_minmax(self, sample_time, sample_count,
                     minval=0., maxval=1., range_check_count=0):

        self._min_sample = minval
        self._max_sample = maxval

    def _raise_callback(self, eventtime):
        range = self._max_sample - self._min_sample
        sample_value = (self._value * range) + self._min_sample
        self._callback(eventtime, sample_value)

    def get_status(self, eventtime):
        return {
            'value': self._value,
            'type': 'adc'
        }

class EndstopVirtualPin(VirtualPin):
    def __init__(self, mcu, pin_params):
        VirtualPin.__init__(self, mcu, pin_params)
        self._steppers = []

    def add_stepper(self, stepper):
        self._steppers.append(stepper)

    def query_endstop(self, print_time):
        return self._value

    def home_start(self, print_time, sample_time, sample_count, rest_time,
                   triggered=True):
        reactor = self._mcu.get_printer().get_reactor()
        completion = reactor.completion()
        completion.complete(True)
        return completion

    def home_wait(self, home_end_time):
        return 1

    def get_steppers(self):
        return list(self._steppers)

    def get_status(self, eventtime):
        return {
            'value': self._value,
            'type': 'endstop'
        }

def load_config(config):
    return VirtualPins(config)
