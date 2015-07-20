'use strict';


import React, // eslint-disable-line no-unused-vars
  { Component, PropTypes } from 'react';

import radium from 'radium';
import mixin from 'react-mixin';
import decorate from 'common-web-ui/lib/decorate';

import Color from 'color';

import DragEventHelpers from '../../mixins/DragEventHelpers';

import {} from 'material-ui';

// import Rectangle from '../../lib/Rectangle';
// import Vector from '../../lib/Vector';

import generateId from '../../lib/generateId';

@radium
@mixin.decorate(DragEventHelpers)
@decorate({
  propTypes: {
    className: PropTypes.string,
    css: PropTypes.object,
    id: PropTypes.string,
    initialColor: PropTypes.string,
    initialName: PropTypes.string,
    style: PropTypes.any
  },
  defaultProps: {
    className: 'GCNodeSocketElement',
    css: {},
    id: null,
    initialColor: 'black',
    initialName: 'port',
    style: null
  },
  contextTypes: {
    graphCanvas: PropTypes.any
  }
})
export default class GCNodeSocketElement extends Component {

  get graphCanvas() {
    return this.context.graphCanvas;
  }

  get graphCanvasViewport() {
    return this.graphCanvas.refs.viewport;
  }

  get linkManager() {
    return this.graphCanvas.refs.links;
  }

  constructor(props) {
    super(props);
    this.props.id = this.props.id || generateId('socket');
  }

  state = {
    color: new Color(this.props.color),
    name: this.props.initialName
  };

  render() {
    var css = this.preparedCSS;

    var typeCell = (
      <div key="type" className="cell" style={css.type}>{this.state.name}</div>
    );

    var socketClassName = 'GraphCanvasSocketIcon socket fa ';

    // var links = model.links;
    var links = [];
    socketClassName += (links.length) ?
      'fa-dot-circle-o' : 'fa-circle-o';

    var socketCell = (
      <div key="socket" className="cell">
        <span style={css.socket}
              className={socketClassName}
              onMouseDown={this.drawLink.bind(this)} />
      </div>
    );

    var dir = this.props.dir,
        cells;

    if (dir[0] === -1) {
      cells = [socketCell, typeCell];
    }
    else if (dir[0] === 1) {
      cells = [typeCell, socketCell];
    }
    else {
      console.error(new Error('Invalid socket dir').stack);
    }

    return (
      <div className="GraphCanvasSocket ungrid"
           data-id={this.props.id}>
        <div className="line">
          {cells}
        </div>
      </div>
    );
  }

  css = {
    socket: {
      padding: 4,
      width: 8,
      height: 8
    },
    type: {
      fontSize: '4px',
      lineHeight: '8px'
    },
    root: null
  };

  get preparedCSS() {
    let props = this.props,
        color = this.state.color;
    return {
      socket: [
        this.css.socket,
        {color: color.hexString()},
        props.css.socket
      ],
      type: [this.css.type, props.css.type],
      root: [this.css.root, props.css.root, props.style]
    };
  }

  drawLink(_event) {
    this.graphCanvasViewport.setupClickDrag({
      down: (event, dragState, e) => this.linksManager.drawLinkStart(event, dragState, e),
      move: (event, dragState, e) => this.linksManager.drawLinkContinue(event, dragState, e),
      up: (event, dragState, e) => this.linksManager.drawLinkFinish(event, dragState, e)
    })(_event);
  }

}
